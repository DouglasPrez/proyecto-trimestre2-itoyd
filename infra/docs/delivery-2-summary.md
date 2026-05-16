# Delivery 2 — Compute, Storage, Database & Remote State

## SportSpace — Sistema de Reservas de Canchas Deportivas

---

## 1. Compute Target & Trade-off

Se eligió **AWS Lambda** como servicio de cómputo para los endpoints de la API de SportSpace.

Lambda representa los casos de uso UC-01 (consulta de disponibilidad) y UC-02 (creación de reservas) como funciones serverless invocadas bajo demanda. La función `proyecto-trimestre2-itoyd-dev-api` fue desplegada con runtime `python3.12`, 128 MB de memoria y 30 segundos de timeout.

**Trade-off principal — Lambda vs ECS Fargate:**

Lambda fue elegido sobre ECS Fargate porque el tráfico de SportSpace es intermitente (los usuarios reservan canchas en horarios específicos, no hay carga constante). Con Lambda se paga únicamente por invocación, lo que lo mantiene dentro del Free Tier de AWS durante el desarrollo. El costo de este trade-off es el **cold start**: la primera invocación tras un período de inactividad tarda entre 200-500ms adicionales.

---

## 2. Diseño de Módulos

Se crearon tres módulos Terraform reutilizables bajo `infra/modules/`:

### `modules/compute/`
Módulo para Lambda function con IAM execution role de permisos mínimos. Expone inputs de `memory_size`, `timeout` y `runtime` para permitir configuración por ambiente. El IAM role usa política inline con permisos explícitos solo a CloudWatch Logs — sin wildcards en `Action` ni `Resource`.

### `modules/storage/`
Módulo para S3 con los cuatro controles de seguridad requeridos: versionado habilitado, lifecycle rule scoped al prefijo `vouchers/` (transición a STANDARD_IA a los 30 días, expiración de versiones no-actuales a los 90 días), encriptación SSE-S3 con AES256, y bucket policy que deniega explícitamente cualquier request sin SSL usando la condición `aws:SecureTransport = false`.

### `modules/database/`
Módulo para DynamoDB con tabla `reservas` diseñada para los casos de uso de SportSpace. Incluye dos GSIs: `espacio-fecha-index` para consultas de disponibilidad por cancha (UC-01) y `usuario-fecha-index` para listar reservas por usuario (UC-03). TTL habilitado en atributo `expires_at` para expiración automática de bloqueos optimistas (UC-02). Encriptación en reposo con SSE habilitado.

Los tres módulos son llamados desde el root module (`infra/main.tf`) con inputs desde variables — sin valores hardcodeados. Los outputs de cada módulo son referenciados en `infra/outputs.tf`.

---

## 3. Migración de Estado Remoto

El estado local de Terraform fue migrado a un backend S3 con locking en DynamoDB mediante un workspace de bootstrap independiente (`infra/bootstrap/`).

### Proceso de migración

**Paso 1 — Bootstrap apply** (desde `infra/bootstrap/` con estado local):
```
terraform init
terraform apply -var="project_name=proyecto-trimestre2-itoyd" -var="region=us-east-1"
```

Outputs del bootstrap:
```
lock_table_name = "proyecto-trimestre2-itoyd-tflock"
region          = "us-east-1"
state_bucket_name = "proyecto-trimestre2-itoyd-tfstate"
```

**Paso 2 — Configurar backend** en `infra/backend.tf` con los valores anteriores.

**Paso 3 — Migración** (desde `infra/`):
```
$ terraform init

Initializing the backend...
Do you want to copy existing state to the new backend? Only 'yes' will be accepted.

Enter a value: yes

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
```

El estado fue verificado en S3:
```
aws s3 ls s3://proyecto-trimestre2-itoyd-tfstate/infra/
2026-05-16 16:22:54   25976 terraform.tfstate
```

---

## 4. Manejo de Credenciales de Base de Datos

DynamoDB fue elegido como motor de base de datos, lo que elimina el riesgo de credenciales hardcodeadas: DynamoDB es un servicio gestionado por AWS que no requiere usuario ni contraseña — el acceso se controla exclusivamente mediante políticas IAM.

En el módulo `modules/database/` no existe ninguna variable de tipo password ni secret. El acceso a la tabla desde la Lambda se grantea mediante el IAM execution role, siguiendo el principio de least privilege: solo las acciones necesarias (`dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:Query`) serán agregadas al role en deliveries posteriores cuando se implemente la lógica de la API.

Esta decisión de diseño elimina por completo el riesgo de credenciales en archivos `.tf`, `.tfvars`, o variables de entorno del pipeline de CI.

---

## 5. Trade-offs Arquitectónicos

### Trade-off 1 — DynamoDB vs RDS PostgreSQL

Se eligió DynamoDB sobre RDS PostgreSQL para el almacenamiento de reservas de SportSpace.

**Justificación:** El patrón de acceso principal de SportSpace es consultar disponibilidad por `espacio_id` y fecha, y listar reservas por `usuario_id` — ambos patrones se mapean directamente a GSIs en DynamoDB sin necesidad de JOINs. RDS requeriría subnet group con múltiples AZs, security groups, y gestión de credenciales, agregando complejidad de red que corresponde al Delivery 3. DynamoDB opera como servicio gestionado sin infraestructura de red adicional, lo que lo hace el candidato correcto para este punto del proyecto. El costo de este trade-off es que las consultas ad-hoc o reportes con múltiples filtros son más complejas sin SQL; esto se mitigaría en producción con un modelo de datos cuidadosamente diseñado o una capa de reporting separada.

### Trade-off 2 — Remote State con S3+DynamoDB vs Estado Local

Se migró el estado de Terraform a un backend remoto S3 con locking en DynamoDB en lugar de mantener estado local.

**Justificación:** El equipo trabaja desde múltiples computadoras, lo que quedó evidenciado durante este delivery cuando un integrante no tenía el `terraform.tfstate` y Terraform intentó recrear recursos ya existentes en AWS. El backend remoto resuelve esto centralizando el estado en S3 (accesible desde cualquier máquina con credenciales AWS) y previniendo applies concurrentes mediante el mecanismo de lock en DynamoDB, demostrado en `evidence/state-lock-contention.png`. El costo de este trade-off es que ahora el workspace de bootstrap debe mantenerse separado y su estado local debe ser preservado; si se pierde, los recursos de tfstate y tflock quedan huérfanos y deben importarse manualmente.

---

## Evidence Index

| Entregable | Archivo de evidencia |
|---|---|
| A — Compute (Lambda) | `evidence/compute-deployed.txt` |
| B — Storage (S3) | `evidence/storage-deployed.txt` |
| C — Database (DynamoDB) | `evidence/database-deployed.txt` |
| D — Remote State (lock) | `evidence/state-lock-contention.png` |