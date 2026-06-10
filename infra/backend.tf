terraform {
  backend "s3" {
    # Partial configuration — key is overridden per environment via
    #   terraform init -backend-config=infra/envs/<env>/backend-<env>.hcl
    bucket         = "proyecto-trimestre2-v2-tfstate"
    region         = "us-east-1"
    dynamodb_table = "proyecto-trimestre2-v2-tflock"
    encrypt        = true
  }
}
