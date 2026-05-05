# Terraform Infrastructure — proyecto-trimestre2-itoyd

This directory contains the Terraform configuration that provisions AWS infrastructure for the project.

## Directory Layout

```
infra/
├── provider.tf          # AWS provider and Terraform version constraints
├── variables.tf         # Input variable declarations
├── main.tf              # Resource definitions
├── outputs.tf           # Output values
├── envs/
│   ├── dev/
│   │   └── dev.tfvars  # Variable values for the dev environment
│   └── prod/           # Variable values for prod (to be added)
├── modules/             # Reusable Terraform modules (to be added)
└── docs/
    └── delivery-1-summary.md
```

---

## Prerequisites

| Tool      | Minimum version |
|-----------|-----------------|
| Terraform | 1.8             |
| AWS CLI   | 2.x (optional)  |

---

## Configure AWS Credentials

Terraform reads credentials from the following environment variables — **never hardcode them**:

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_REGION="us-east-1"
```

You can also use an [AWS named profile](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html):

```bash
export AWS_PROFILE=my-profile
```

---

## Initialize Terraform

Run the following command from the `infra/` directory:

```bash
cd infra
terraform init
```

This downloads the required provider plugins. Use `-backend=false` to skip remote-state configuration during local development:

```bash
terraform init -backend=false
```

---

## Plan

Preview the changes Terraform will make against the **dev** environment:

```bash
terraform plan -var-file="envs/dev/dev.tfvars"
```

---

## Apply

Apply the changes to create or update real AWS resources:

```bash
terraform apply -var-file="envs/dev/dev.tfvars"
```

Add `-auto-approve` to skip the interactive confirmation prompt (use with caution in CI):

```bash
terraform apply -var-file="envs/dev/dev.tfvars" -auto-approve
```

---

## Destroy

Remove all resources managed by this configuration:

```bash
terraform destroy -var-file="envs/dev/dev.tfvars"
```

---

## CI Pipeline

A GitHub Actions workflow at `.github/workflows/terraform-ci.yml` runs automatically on every pull request targeting `main`. It performs:

1. **Format check** — `terraform fmt --check -recursive`
2. **Init** — `terraform init -backend=false`
3. **Validate** — `terraform validate`
4. **Plan** — `terraform plan -var-file="envs/dev/dev.tfvars"`

The pipeline uses the GitHub Secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_REGION`.
