# Infraestructura con Terraform — proyecto-trimestre2-itoyd

Esta configuración de Terraform forma parte del Delivery 1 y tiene como objetivo establecer una infraestructura mínima funcional y un pipeline de integración continua (CI) para despliegues en AWS.

Este directorio contiene la configuración de Terraform que aprovisiona infraestructura en AWS para el proyecto.

---

## Estructura del Proyecto

```
infra/
├── provider.tf          # Proveedor AWS y restricciones de versión de Terraform
├── variables.tf         # Declaración de variables de entrada
├── main.tf              # Definición de recursos
├── outputs.tf           # Valores de salida
├── envs/
│   ├── dev/
│   │   └── dev.tfvars  # Valores de variables para el entorno de desarrollo
│   └── prod/           # Valores de variables para producción (pendiente)
├── modules/             # Módulos reutilizables (pendiente)
└── docs/
    └── delivery-1-summary.md
```

---

## Prerrequisitos

| Herramienta | Versión mínima |
| ----------- | -------------- |
| Terraform   | 1.8            |
| AWS CLI     | 2.x (opcional) |

---

## Configuración de Credenciales AWS

Terraform utiliza las siguientes variables de entorno para autenticarse — **nunca se deben hardcodear en el código**:

```bash
export AWS_ACCESS_KEY_ID="TU_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="TU_SECRET_KEY"
export AWS_REGION="TU_REGION"
```

También puedes usar un perfil configurado en AWS CLI:

```bash
export AWS_PROFILE=mi-perfil
```

---

## Inicializar Terraform

Ejecuta el siguiente comando desde el directorio `infra/`:

```bash
cd infra
terraform init
```

Este comando descarga los proveedores necesarios.

Para desarrollo local sin backend remoto:

```bash
terraform init -backend=false
```

---

## Plan

Previsualiza los cambios que Terraform realizará en el entorno de desarrollo:

```bash
terraform plan -var-file="envs/dev/dev.tfvars"
```

Este comando utiliza la configuración del entorno de desarrollo definida en `envs/dev/dev.tfvars`.

---

## Apply

Aplica los cambios para crear o actualizar recursos reales en AWS:

```bash
terraform apply -var-file="envs/dev/dev.tfvars"
```

```bash
terraform apply -var-file="envs/dev/dev.tfvars" -auto-approve
```

> Nota: Este comando crea recursos reales en AWS que pueden generar costos dependiendo del uso.

---

## Destroy

Elimina todos los recursos gestionados por esta configuración:

```bash
terraform destroy -var-file="envs/dev/dev.tfvars"
```

---

## Pipeline de Integración Continua (CI)

Se ha configurado un pipeline en GitHub Actions ubicado en:

```
.github/workflows/terraform-ci.yml
```

Este pipeline se ejecuta automáticamente en cada Pull Request hacia la rama `main` y realiza las siguientes validaciones:

1. **Formato** — `terraform fmt --check -recursive`
2. **Inicialización** — `terraform init -backend=false`
3. **Validación** — `terraform validate`
4. **Plan** — `terraform plan -var-file="envs/dev/dev.tfvars"`

Además, el pipeline publica automáticamente el resultado del `terraform plan` como comentario en el Pull Request.

El pipeline utiliza los siguientes secretos configurados en GitHub:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_REGION`

Esto garantiza una autenticación segura sin exponer credenciales en el repositorio.

---
