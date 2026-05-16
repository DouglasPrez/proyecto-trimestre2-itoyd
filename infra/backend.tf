terraform {
  backend "s3" {
    bucket         = "proyecto-trimestre2-itoyd-tfstate"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "proyecto-trimestre2-itoyd-tflock"
    encrypt        = true
  }
}
