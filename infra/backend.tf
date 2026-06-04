terraform {
  backend "s3" {
    bucket         = "proyecto-trimestre2-v2-tfstate"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "proyecto-trimestre2-v2-tflock"
    encrypt        = true
  }
}
