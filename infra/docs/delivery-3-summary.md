# Delivery 3 — Summary: SportSpace Networking Layer

## SportSpace — Sistema de Reservas de Canchas Deportivas

| | |
|---|---|
| **Equipo** | Douglas Perez · Carlos Daniel Martinez · Ana Isabel Perez |
| **Entrega** | Delivery 3 de 5 — Networking Layer |
| **Track** | Serverless-Only |

---

## 1. Networking Track y Rationale

El equipo está en el **track serverless-only**.

**Por qué califica:**
- Cómputo: **AWS Lambda** (`proyecto-trimestre2-itoyd-dev-api`, runtime `python3.12`) — definido en `infra/modules/compute/`.
- Base de datos: **Amazon DynamoDB** (tabla `proyecto-trimestre2-itoyd-dev-reservas`, billing mode `PAY_PER_REQUEST`) — definida en `infra/modules/database/`.

Ambos servicios son completamente serverless: no viven en una VPC, no tienen ENIs persistentes y no requieren subnets ni NAT Gateway para operar. Por esta razón no aplica el track VPC-required.

El track serverless-only substituye la VPC por un **Edge & DNS deliverable**: dominio personalizado, hosted zone en Route 53, certificado ACM, validación DNS y custom domain en API Gateway.

**Dominio:** `api.sportspace.example.com`
*(Sustituir con el subdominio real provisto por los instructores o el dominio del equipo antes de hacer apply. El dominio fue [fuente: sub-delegado por instructores / registrado por el equipo — actualizar esta línea].)*

---

## 2. Módulo y Arquitectura DNS

El módulo `infra/modules/network/` implementa el Edge & DNS para el track serverless-only.

**Inputs que acepta:**

| Variable | Descripción |
|---|---|
| `domain_name` | Dominio personalizado (e.g. `api.sportspace.example.com`) |
| `aws_region` | Región AWS — debe coincidir con la región del API Gateway |
| `api_gateway_id` | ID del HTTP API Gateway (del output de `module.ingress`) |
| `api_gateway_stage_name` | Stage a bindear al custom domain (`dev`) |
| `lambda_function_name` | Nombre de la Lambda para el `aws_lambda_permission` |
| `api_gateway_execution_arn` | ARN de ejecución del API GW para scopear el permiso |
| `environment` / `project_name` | Tagging estándar |

**Outputs que expone:**

| Output | Valor |
|---|---|
| `domain_name` | Dominio registrado en API Gateway |
| `hosted_zone_id` | ID de la hosted zone Route 53 |
| `hosted_zone_name_servers` | NSes para configurar en el registrador |
| `api_custom_endpoint` | URL pública HTTPS del custom domain |
| `certificate_arn` | ARN del certificado ACM emitido |

**Estrategia ACM:** Se usa un certificado **regional** (misma región que API Gateway, `us-east-1`), con `validation_method = "DNS"`. Los registros CNAME de validación se crean en la hosted zone de Route 53 vía `aws_route53_record` y se espera la emisión con `aws_acm_certificate_validation`.

**Wiring al API stage:** El custom domain se bindea al stage `dev` del API Gateway vía `aws_apigatewayv2_api_mapping`. El record `A ALIAS` en Route 53 apunta al `target_domain_name` del `aws_apigatewayv2_domain_name`.

---

## 3. D2 Wiring Update

En Delivery 2, el módulo `compute` usaba un placeholder ZIP con código hardcodeado y no tenía variables de entorno para conectarse a DynamoDB ni a S3.

**Cambios realizados en D3:**

1. `modules/compute/main.tf` — el placeholder fue reemplazado por `data.archive_file.handler` que empaqueta `src/index.py` (el handler real del E2E proof).
2. `modules/compute/main.tf` — se agregaron tres políticas IAM inline: `lambda_logs` (CloudWatch, sin cambios), `lambda_dynamodb` (Scan/Query/GetItem/PutItem scoped al ARN específico de la tabla), y `lambda_s3` (PutObject/GetObject scoped al ARN específico del bucket).
3. `modules/compute/main.tf` — se inyectan `DYNAMODB_TABLE` y `S3_BUCKET` como variables de entorno en la Lambda function resource.
4. `modules/compute/variables.tf` — se agregaron `dynamodb_table_name`, `dynamodb_table_arn`, `s3_bucket_name`, `s3_bucket_arn`.
5. `infra/main.tf` — el `module.compute` ahora consume los outputs de `module.database` y `module.storage`.

DynamoDB y S3 son servicios gestionados fuera de VPC — no tenían placeholder de VPC ni subnet group en D2, por lo que no hay refactoring de networking placeholder para estos recursos.

```
terraform output

api_custom_endpoint         = "https://api.sportspace.example.com"
api_gateway_endpoint        = "https://XXXXX.execute-api.us-east-1.amazonaws.com/dev"
api_gateway_id              = "XXXXX"
database_table_arn          = "arn:aws:dynamodb:us-east-1:676206925447:table/proyecto-trimestre2-itoyd-dev-reservas"
database_table_name         = "proyecto-trimestre2-itoyd-dev-reservas"
hosted_zone_id              = "ZXXXXXXXXXXXX"
lambda_function_arn         = "arn:aws:lambda:us-east-1:676206925447:function:proyecto-trimestre2-itoyd-dev-api"
storage_bucket_name         = "proyecto-trimestre2-itoyd-dev-storage"
```
*(Actualizar con los valores reales después del apply)*

---

## 4. Seguridad

**Track serverless-only — controles aplicados:**

### Ingress restriction (Deliverable B)
Se usa `aws_lambda_permission` con `source_arn` scopeado al execution ARN del API Gateway específico (`${module.ingress.execution_arn}/*/*`). Esto previene la invocación directa de la Lambda via URL directa o cualquier otro API Gateway — solo el API Gateway de SportSpace puede invocarla.

### Least-privilege invoker IAM (Deliverable B)
El IAM execution role de la Lambda tiene tres políticas inline separadas, ninguna con wildcard en `Resource`:

- **CloudWatch Logs:** `logs:CreateLogGroup/Stream/PutLogEvents` → scoped al log group `/aws/lambda/proyecto-trimestre2-itoyd-dev-api:*`.
- **DynamoDB:** `GetItem`, `PutItem`, `UpdateItem`, `DeleteItem`, `Scan`, `Query` → scoped al ARN de `proyecto-trimestre2-itoyd-dev-reservas` y sus índices.
- **S3:** `PutObject`, `GetObject`, `DeleteObject` → scoped a `arn:aws:s3:::proyecto-trimestre2-itoyd-dev-storage/*`.

No existe ninguna política con `"Resource": "*"` en la cuenta — esto sería una violación explícita de least-privilege según el rubric.

---

## 5. End-to-End Connectivity Proof Architecture

**Runtime:** Python 3.12 en AWS Lambda (`src/index.py`).

### Flujo de credenciales sensibles
```
GitHub Actions repository secret (DB_PASSWORD)
  → TF_VAR_db_password en el CI runner (env var, nunca en .tfvars)
  → variable Terraform declarada con sensitive = true (si aplica)
  → NO se usa DB_PASSWORD en D3 (DynamoDB no requiere password — usa IAM roles)
```

Para DynamoDB el acceso es completamente basado en IAM: no hay credenciales, no hay password. El rol de ejecución de la Lambda (`proyecto-trimestre2-itoyd-dev-api-exec-role`) tiene las políticas IAM definidas en `modules/compute/main.tf`.

### IAM execution role y ARNs con acceso

| Permiso | ARN de Resource |
|---|---|
| DynamoDB Scan/Query/GetItem/PutItem | `arn:aws:dynamodb:us-east-1:676206925447:table/proyecto-trimestre2-itoyd-dev-reservas` |
| DynamoDB GSI access | `arn:aws:dynamodb:us-east-1:676206925447:table/proyecto-trimestre2-itoyd-dev-reservas/index/*` |
| S3 PutObject/GetObject | `arn:aws:s3:::proyecto-trimestre2-itoyd-dev-storage/*` |

*(Actualizar account ID con el valor real)*

### Seed data
El ítem de seed se inserta vía `aws_dynamodb_table_item` en `infra/seed/seed.tf`, llamado como `module.seed` desde el root module. Esto garantiza que el ítem sea reproducible, revisable por los graders, y no requiera intervención manual en la consola. El seed crea una reserva confirmada con `reserva_id = "SEED-001"` en la tabla.

---

## 6. Trade-offs Arquitectónicos

### Trade-off 1 — API Gateway HTTP API vs REST API
Se eligió **HTTP API** (V2) sobre REST API (V1) por dos razones:

- **Costo:** HTTP API cobra $1.00 por millón de requests vs $3.50 de REST API — una reducción del 71% para el MVP.
- **Latencia:** HTTP API tiene menor overhead de procesamiento (~10-20ms menos por request).

El trade-off es que HTTP API no soporta nativamente AWS WAF ni algunos features de REST API como usage plans y API keys. Para el MVP de SportSpace, donde no hay plan de monetización por API key ni necesidad de WAF en D3, esta limitación es aceptable. Si en D5 se requiere WAF, se puede migrar a REST API o usar CloudFront delante del HTTP API.

### Trade-off 2 — Dominio personalizado vs URL default del API Gateway
Se eligió configurar un **dominio personalizado** (`api.sportspace.example.com`) en lugar de usar la URL default (`XXXXX.execute-api.us-east-1.amazonaws.com/dev`).

La URL default cambia si el API Gateway es destruido y recreado (e.g. durante un destroy/apply en CI). Un dominio personalizado es estable: el cliente (app frontend, integraciones) siempre apunta al mismo endpoint sin imports de refactoring.

El trade-off es la complejidad adicional: requiere ACM + Route 53 + api mapping + propagación DNS (que puede tomar hasta 48h para el NS delegation). Para un sistema de reservas en producción, la estabilidad del endpoint justifica completamente esta complejidad. En D5 cuando se agregue HTTPS/TLS propio, el custom domain también es el punto de configuración correcto.
