# Delivery 1 — Summary

## Selección del Proveedor Cloud

Se seleccionó Amazon Web Services (AWS) como proveedor de nube debido a su amplia adopción en la industria, extensa documentación y disponibilidad de un nivel gratuito (Free Tier) adecuado para entornos de desarrollo y pruebas iniciales. Además, AWS se integra fácilmente con Terraform y GitHub Actions, lo cual facilita la automatización del aprovisionamiento de infraestructura y la implementación de pipelines de CI/CD.

La región seleccionada fue **us-east-1**, ya que ofrece alta disponibilidad, soporte completo de servicios y es comúnmente utilizada para entornos de desarrollo.

---

## Explicación del Recurso

Para este delivery se aprovisionó un único recurso: un bucket de Amazon S3. Este recurso funciona como una prueba de concepto para validar que la configuración de Terraform, las credenciales y la integración con el pipeline de CI funcionan correctamente.

El bucket se configura utilizando variables como `bucket_name`, `project_name` y `environment`, lo cual permite reutilizar la configuración en distintos entornos. Además, se aplican etiquetas (tags) para identificar el proyecto y el entorno, siguiendo buenas prácticas de organización en AWS.

Aunque el requisito mínimo es un solo recurso, este bucket representa la base sobre la cual se construirá la infraestructura completa en los siguientes deliveries.

---

## Explicación del Pipeline de CI

Se implementó un pipeline utilizando GitHub Actions que se ejecuta automáticamente en cada pull request hacia la rama `main`. Este pipeline valida que la configuración de Terraform sea correcta antes de permitir su integración.

El flujo del pipeline incluye los siguientes pasos:

1. **terraform fmt --check -recursive**
   Verifica que todos los archivos de Terraform cumplan con el formato estándar.

2. **terraform init -backend=false**
   Inicializa el entorno de trabajo y descarga los proveedores sin configurar un backend remoto.

3. **terraform validate**
   Realiza una validación estática de la configuración para detectar errores de sintaxis o estructura.

4. **terraform plan -var-file=envs/dev/dev.tfvars**
   Genera un plan de ejecución utilizando variables del entorno de desarrollo, confirmando que la infraestructura puede ser creada correctamente.

El pipeline utiliza secretos en GitHub (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`) para autenticar con AWS de forma segura, evitando exponer credenciales en el repositorio.

---

## Diseño de Variables

Se definieron las siguientes variables en `variables.tf`:

* **environment (string):** Define el entorno de despliegue (por ejemplo, dev o prod).
* **project_name (string):** Nombre del proyecto utilizado para etiquetar recursos.
* **region (string):** Región de AWS donde se desplegarán los recursos.
* **bucket_name (string):** Nombre del bucket S3 a crear.

Cada variable incluye su descripción y tipo de dato, lo que mejora la claridad y mantenibilidad del código. Este diseño permite reutilizar la misma configuración de Terraform en distintos entornos mediante archivos `.tfvars`, facilitando la escalabilidad.

---

## Decisiones y Trade-offs

### 1. Uso de estado local en lugar de backend remoto

Se decidió utilizar el estado local de Terraform para este delivery, ya que simplifica la configuración inicial y cumple con los requisitos establecidos. La desventaja es que no es adecuado para trabajo en equipo o entornos productivos, pero se planea migrar a un backend remoto en futuros deliveries.

### 2. Infraestructura mínima (un solo recurso)

Se optó por implementar únicamente un bucket S3 para cumplir estrictamente con el requisito mínimo del delivery. Aunque se podrían haber agregado configuraciones adicionales (como versionado o encriptación), se priorizó la simplicidad y claridad. El trade-off es que la solución es menos completa, pero permite enfocarse en validar la estructura de Terraform y el pipeline de CI.

---
