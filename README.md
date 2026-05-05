# proyecto-trimestre2-itoyd

Este repositorio contiene el proyecto correspondiente al segundo trimestre del postgrado en diseño y desarrollo de software (PDDS).

## Overview

The project provisions AWS infrastructure using **Terraform** following Infrastructure as Code (IaC) best practices.

## Repository Structure

```
.
├── infra/                  # Terraform configuration
│   ├── provider.tf         # AWS provider & version constraints
│   ├── variables.tf        # Input variables
│   ├── main.tf             # Resource definitions
│   ├── outputs.tf          # Output values
│   ├── envs/
│   │   ├── dev/
│   │   │   └── dev.tfvars  # Dev environment variable values
│   │   └── prod/           # Prod environment variable values (TBD)
│   ├── modules/            # Reusable modules (TBD)
│   ├── docs/
│   │   └── delivery-1-summary.md
│   └── README.md           # Detailed Terraform usage guide
└── .github/
    └── workflows/
        └── terraform-ci.yml  # GitHub Actions CI pipeline
```

See [infra/README.md](infra/README.md) for detailed instructions on how to initialize Terraform, configure AWS credentials, and run plan/apply.
