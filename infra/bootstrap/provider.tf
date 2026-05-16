terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # SIN bloque backend{} — estado local por diseño
}

provider "aws" {
  region = var.region
}
