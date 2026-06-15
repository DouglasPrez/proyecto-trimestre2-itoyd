# Delivery 4 — Async Infrastructure & Full CD Pipeline

## SportSpace — Sistema de Reservas de Canchas Deportivas

| | |
|---|---|
| **Equipo** | Douglas Perez · Carlos Daniel Martinez · Ana Isabel Perez |
| **Entrega** | Delivery 4 de 5 — Async Infrastructure & Full CD Pipeline |
| **Track** | Serverless-Only |
| **Tag** | `oyd-delivery-4` |

---

## 1. Async Messaging Design

Se eligió **SQS Standard** (no FIFO) como servicio de mensajería asíncrona.

**Por qué Standard y no FIFO:** El caso de uso de SportSpace no requiere orden estricto de procesamiento. Los mensajes de reservas se encolan desde el endpoint `POST /reservations/enqueue` y son procesados por el consumer asíncrono que escribe en S3. El orden no importa porque cada mensaje es independiente. SQS Standard ofrece mayor throughput (prácticamente ilimitado vs 3000 msg/s de FIFO) y menor costo.

**Configuración DLQ:**
- `max_receive_count = 5` — un mensaje se reintenta hasta 5 veces antes de ir al DLQ. Es un balance entre permitir recuperación transitoria (timeouts de Lambda, conexiones) y no reintentar indefinidamente mensajes inválidos.
- `message_retention_seconds = 345600` (4 días) para la cola principal y `dlq_message_retention_seconds = 1209600` (14 días) para la DLQ. La DLQ retiene más tiempo porque los mensajes fallidos requieren revisión manual.
- `visibility_timeout_seconds = 30` — tiempo suficiente para que el consumer Lambda procese un mensaje (timeout del consumer: 60s, batch_size: 10).

El DLQ permite inspeccionar mensajes que fallaron repetidamente sin perderlos. El equipo planea revisar la DLQ periódicamente y, si los mensajes tienen errores de formato, corregir el código del producer; si son errores de infraestructura, re-encolarlos manualmente o ajustar el `max_receive_count`.

---

## 2. Event-Driven Architecture

El consumer asíncrono es una **Lambda function separada** (`proyecto-trimestre2-{env}-async-consumer`) activada por un **event source mapping** de SQS.

**Configuración del event source mapping:**
- `batch_size = 10` — máximo de 10 mensajes por invocación. Suficiente para el volumen del MVP sin saturar el consumer.
- `maximum_batching_window_in_seconds = 5` — espera hasta 5 segundos para llenar el batch antes de invocar.
- `bisect_batch_on_function_error = false` — en dev se deshabilita para simplificar; en staging se habilita (`true`) para aislar mensajes defectuosos.

**Flujo de errores al DLQ:**
1. Lambda recibe un batch de SQS.
2. Si el handler `async_consumer` lanza una excepción, SQS reintenta el mensaje según el `max_receive_count`.
3. Después de agotar los reintentos, SQS mueve el mensaje al DLQ automáticamente vía `redrive_policy`.
4. El equipo puede inspeccionar la DLQ en la consola AWS, corregir el problema, y re-encolar mensajes manualmente.

**IAM least privilege:** El execution role de la Lambda tiene scoped a la queue ARN específica: `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes` (para el consumer) y `sqs:SendMessage` (para el producer en la API Lambda). Ningún recurso usa `"Resource": "*"`.

---

## 3. Terraform Environment Layout and CD Pipeline

### Multi-Environment Directory Structure

```
infra/envs/
├── dev/
│   ├── dev.tfvars
│   └── backend-dev.hcl
└── staging/
    ├── staging.tfvars
    └── backend-staging.hcl
```

**Pattern elegido:** Backend configs separados (Pattern A). Cada ambiente tiene su propio archivo `backend-{env}.hcl` que especifica un `key` diferente en S3 (`infra/envs/dev/terraform.tfstate` vs `infra/envs/staging/terraform.tfstate`). Se eligió este patrón sobre Terraform workspaces porque:

- **Explicitud:** Cada ambiente tiene un archivo de backend versionable y revisable en PR.
- **Simplicidad:** No requiere comandos `terraform workspace` en CI, eliminando el riesgo de olvidar seleccionar el workspace.
- **Separación total:** Los estados están aislados incluso si alguien ejecuta comandos localmente sin backend config.

### Variables que difieren entre dev y staging

| Variable | dev | staging | Razón |
|---|---|---|---|
| `lambda_memory_size` | 128 MB | 256 MB | Staging recibe más memoria para simular carga de producción |
| `async_max_receive_count` | 5 | 3 | Staging es más estricto: menos reintentos antes de DLQ |
| `async_visibility_timeout_seconds` | 30s | 60s | Staging da más tiempo por mensaje para simular latencia real |
| `event_batch_size` | 10 | 5 | Staging procesa batches más pequeños para mejor aislamiento |
| `async_consumer_memory_size` | 128 MB | 256 MB | Consumer de staging con más memoria |
| `async_consumer_timeout` | 60s | 120s | Consumer de staging con más tiempo |

### Plan-Artifact Promotion

El workflow de PR (`pr-plan.yml`) ejecuta `terraform plan -out=tfplan-{env}` para ambos ambientes y sube los planes como artefactos (`actions/upload-artifact`). También publica el output del plan como comentario en el PR.

El workflow de CD (`cd-apply.yml`) se activa al hacer merge a `main`:
1. **Dev:** descarga el artifact `tfplan-dev`, ejecuta `terraform apply tfplan-dev`.
2. **Staging:** después de que dev apply es exitoso, descarga `tfplan-staging` y ejecuta `terraform apply tfplan-staging`.

Ningún `terraform apply` corre sin el artifact — no se re-planifica en merge.

### GitHub Environments

| Environment | Required Reviewers | Secrets Namespaced | Deploy Trigger |
|---|---|---|---|
| `dev` | None | `DEV_SECRET_KEY` | Automático al merge a `main` |
| `staging` | 1 required reviewer | `STAGING_SECRET_KEY` | Manual approval después de dev apply |

**Reviewer:** Douglas Perez (revisor designado para staging approval gate).

### Branch Protection Ruleset

Configurado en Settings → Rules → Rulesets, targeting `main`, estado **Active**:

- **Require a pull request before merging** — sin pushes directos a main.
- **Required status checks:** `terraform fmt`, `terraform validate`, `terraform plan` — estos checks son producidos por jobs nombrados en `pr-plan.yml`. Los nombres en el ruleset coinciden exactamente con los job names del workflow.
- **Require branches to be up to date** — la rama del PR debe estar actualizada con main antes de mergear, forzando a re-correr checks.
- **Block force pushes** — protege contra rewrites de historia.
- **Block deletions** — la rama main no puede ser eliminada.

---

## 4. Scheduled Jobs

**Función:** Health-ping del API principal (invoca la Lambda `proyecto-trimestre2-{env}-api`).

**Cron expression:** `cron(0 6 * * ? *)` — todos los días a las 06:00 AM hora Guatemala (UTC-6).

**Target:** Lambda API principal vía `aws_scheduler_schedule`.

**IAM scope:** El rol del scheduler (`proyecto-trimestre2-{env}-scheduler-role`) tiene únicamente `lambda:InvokeFunction` scoped al ARN específico de la función API. No hay wildcard. Este rol es más restringido que el execution role de Lambda porque el scheduler solo necesita invocar, no ejecutar lógica de negocio ni acceder a bases de datos o storage.

**Time zone:** `America/Guatemala` — el equipo opera en horario Guatemala. La ejecución a las 6 AM asegura que el health-ping ocurra antes del horario laboral típico de los usuarios.

---

## 5. End-to-End Async Proof

**Runtime:** Python 3.12 en AWS Lambda.

**Flujo complete (enqueue → consumer → S3):**

1. **Producer** — El endpoint `POST /reservations/enqueue` (a través del API Gateway, dominio `grupo2.oyd.solid.com.gt`) recibe un JSON body, genera un `message_id` (UUID v4), construye el mensaje con `message_id`, `payload` y `timestamp`, y lo envía a la SQS queue mediante `sqs_client.send_message`. Retorna HTTP 202 con el `message_id`.
2. **Queue** — SQS retiene el mensaje y lo entrega al event source mapping configurado en el consumer Lambda.
3. **Consumer** — La función `async_consumer` (handler `index.async_consumer`) es invocada por SQS con un batch de mensajes. Por cada mensaje, lee el `message_id` del cuerpo, construye un object key en formato `async/{timestamp}-{message_id}.json`, y escribe el mensaje completo al bucket S3.

**IAM execution role** scoped a:
- Queue ARN: `arn:aws:sqs:us-east-1:{account}:proyecto-trimestre2-{env}-reservations`
- Bucket ARN: `arn:aws:s3:::proyecto-trimestre2-{env}-storage/*`

**Object key derivation:** `async/{YYYYMMDDTHHMMSSZ}-{message_id}.json`. El timestamp permite ordenar objetos por fecha de procesamiento; el `message_id` (UUID) garantiza unicidad.

**Seed data:** Se envía un mensaje de prueba vía `curl -X POST ... /reservations/enqueue` (no inserción manual en consola AWS).

---

## 6. Two Architectural Trade-offs

### Trade-off 1 — SQS Standard vs. FIFO

Se eligió **SQS Standard** sobre FIFO para la cola de mensajería asíncrona.

**Justificación:** El caso de uso de SportSpace no requiere orden estricto de procesamiento. Cada mensaje representa una reserva independiente; no hay dependencias entre mensajes consecutivos donde el orden de escritura a S3 importe. SQS Standard ofrece:
- Throughput prácticamente ilimitado (vs 3000 msg/s con FIFO).
- Menor latencia en la entrega de mensajes.
- Sin costo adicional por operación FIFO.
- Sin la restricción de `message group ID` que FIFO requiere.

El trade-off es que Standard no garantiza exactly-once delivery (pueden haber duplicados). Para SportSpace, donde el consumer escribe en S3 de forma idempotente (cada mensaje genera un object key único), los duplicados no causan problemas de datos. Si en el futuro se requiriera orden estricto (ej. para eventos de facturación encadenados), se podría migrar a FIFO cambiando el tipo de queue y agregando `message_group_id` en el producer.

### Trade-off 2 — Separate Backend Configs vs. Terraform Workspaces

Se eligió **backend configs separados (Pattern A)** sobre Terraform workspaces para la separación de estado multi-ambiente.

**Justificación:** Los backend configs separados ofrecen:
- **Explicitud:** Cada ambiente tiene un archivo de backend versionable (`backend-dev.hcl`, `backend-staging.hcl`) que se revisa en PR. Cualquier cambio en la configuración de estado pasa por code review.
- **Aislamiento total:** No hay riesgo de que un `terraform apply` accidental apunte al estado de otro ambiente por no haber seleccionado el workspace correcto.
- **CI simple:** El workflow pasa el archivo de backend correspondiente vía `-backend-config=infra/envs/{env}/backend-{env}.hcl`. No hay comandos `terraform workspace select` que puedan fallar si el workspace no existe.

El trade-off es que con workspaces el backend S3 tiene un solo bucket con un solo archivo de configuración, simplificando el bootstrap inicial. Sin embargo, para un equipo de 3 personas con CI/CD automatizado, la explicitud y seguridad de backend configs separados justifica la complejidad adicional del bootstrap (un `terraform init` por ambiente).

---

## Evidence Index

| Deliverable | Evidence File |
|---|---|
| A — Async Messaging | `infra/evidence/async-foundation.txt` |
| B — Event-Driven Compute | `infra/evidence/event-source-plan.txt` + `infra/evidence/event-source.png` |
| C — Scheduled Jobs | `infra/evidence/scheduler.png` + `infra/evidence/scheduler-plan.txt` |
| D — CD Pipeline | `infra/evidence/github-environments.png`, `ci-apply-dev.png`, `ci-apply-staging.png`, `ci-destroy.png`, `ci-drift.png`, `ruleset-config.png`, `ruleset-blocked-merge.png` |
| E — End-to-End Async | `infra/evidence/async-enqueue.txt`, `infra/evidence/async-consumer.png`, `infra/evidence/async-object.png` |
