terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Credentials are read from the environment variables:
  #   AWS_ACCESS_KEY_ID
  #   AWS_SECRET_ACCESS_KEY
  # Do NOT hardcode credentials here.
}
