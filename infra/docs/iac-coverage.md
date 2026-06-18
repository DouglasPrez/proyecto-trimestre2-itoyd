# IaC Coverage — Delivery 5

This document proves that every cloud resource used by SportSpace is managed by Terraform. No manually created resources exist.

## Component-to-IaC Mapping

| Application Component | Cloud Service Used | Terraform Resource Type | Module Path |
|---|---|---|---|
| **Compute — API Lambda** | AWS Lambda | `aws_lambda_function` | `infra/modules/compute/main.tf` |
| **Compute — Async Consumer Lambda** | AWS Lambda | `aws_lambda_function` | `infra/modules/compute/main.tf` |
| **Storage — Vouchers bucket** | AWS S3 | `aws_s3_bucket` | `infra/modules/storage/main.tf` |
| **Storage — Bucket versioning** | AWS S3 | `aws_s3_bucket_versioning` | `infra/modules/storage/main.tf` |
| **Storage — SSE encryption** | AWS S3 | `aws_s3_bucket_server_side_encryption_configuration` | `infra/modules/storage/main.tf` |
| **Storage — Lifecycle rules** | AWS S3 | `aws_s3_bucket_lifecycle_configuration` | `infra/modules/storage/main.tf` |
| **Storage — Public access block** | AWS S3 | `aws_s3_bucket_public_access_block` | `infra/modules/storage/main.tf` |
| **Storage — Bucket policy** | AWS S3 | `aws_s3_bucket_policy` | `infra/modules/storage/main.tf` |
| **Database — DynamoDB reservas** | AWS DynamoDB | `aws_dynamodb_table` | `infra/modules/database/main.tf` |
| **Seed data — DynamoDB items** | AWS DynamoDB | `aws_dynamodb_table_item` | `infra/seed/seed.tf` |
| **Ingress — API Gateway HTTP API** | AWS API Gateway | `aws_apigatewayv2_api` | `infra/modules/ingress/main.tf` |
| **Ingress — Lambda integration** | AWS API Gateway | `aws_apigatewayv2_integration` | `infra/modules/ingress/main.tf` |
| **Ingress — Routes** | AWS API Gateway | `aws_apigatewayv2_route` | `infra/modules/ingress/main.tf` |
| **Ingress — Stage** | AWS API Gateway | `aws_apigatewayv2_stage` | `infra/modules/ingress/main.tf` |
| **Ingress — Lambda permission** | AWS Lambda | `aws_lambda_permission` | `infra/modules/network/main.tf` |
| **Network — Route53 zone (data)** | AWS Route53 | `data.aws_route53_zone` | `infra/modules/network/main.tf` |
| **Network — Custom domain** | AWS API Gateway | `aws_apigatewayv2_domain_name` | `infra/modules/network/main.tf` |
| **Network — API mapping** | AWS API Gateway | `aws_apigatewayv2_api_mapping` | `infra/modules/network/main.tf` |
| **Network — Route53 alias record** | AWS Route53 | `aws_route53_record` | `infra/modules/network/main.tf` |
| **TLS — ACM certificate** | AWS ACM | `aws_acm_certificate` | `infra/modules/network/main.tf` |
| **TLS — ACM cert validation** | AWS ACM | `aws_acm_certificate_validation` | `infra/modules/network/main.tf` |
| **TLS — CloudFront redirect** | AWS CloudFront | `aws_cloudfront_distribution` | `infra/main.tf` |
| **Async — SQS queue** | AWS SQS | `aws_sqs_queue` | `infra/modules/async/main.tf` |
| **Async — DLQ** | AWS SQS | `aws_sqs_queue` | `infra/modules/async/main.tf` |
| **Async — Event source mapping** | AWS Lambda | `aws_lambda_event_source_mapping` | `infra/modules/compute/main.tf` |
| **Scheduler — EventBridge schedule** | AWS EventBridge Scheduler | `aws_scheduler_schedule` | `infra/modules/scheduler/main.tf` |
| **Scheduler — IAM role** | AWS IAM | `aws_iam_role` | `infra/modules/scheduler/main.tf` |
| **Scheduler — IAM policy** | AWS IAM | `aws_iam_role_policy` | `infra/modules/scheduler/main.tf` |
| **Security — IAM compute role** | AWS IAM | `aws_iam_role` | `infra/modules/iam/main.tf` |
| **Security — IAM async consumer role** | AWS IAM | `aws_iam_role` | `infra/modules/iam/main.tf` |
| **Security — IAM CI runner role** | AWS IAM | `aws_iam_role` | `infra/modules/iam/main.tf` |
| **Security — IAM role policies** | AWS IAM | `aws_iam_role_policy` | `infra/modules/iam/main.tf` |
| **Security — OIDC provider** | AWS IAM | `aws_iam_openid_connect_provider` | `infra/main.tf` |
| **Encryption — KMS CMK** | AWS KMS | `aws_kms_key` | `infra/main.tf` |
| **Encryption — KMS alias** | AWS KMS | `aws_kms_alias` | `infra/main.tf` |
| **Secrets — JWT signing key** | AWS Secrets Manager | `aws_secretsmanager_secret` | `infra/main.tf` |
| **Secrets — Secret version** | AWS Secrets Manager | `aws_secretsmanager_secret_version` | `infra/main.tf` |
| **Observability — API log group** | AWS CloudWatch Logs | `aws_cloudwatch_log_group` | `infra/modules/observability/main.tf` |
| **Observability — Async consumer log group** | AWS CloudWatch Logs | `aws_cloudwatch_log_group` | `infra/modules/observability/main.tf` |
| **Observability — SNS topic** | AWS SNS | `aws_sns_topic` | `infra/modules/observability/main.tf` |
| **Observability — Email subscription** | AWS SNS | `aws_sns_topic_subscription` | `infra/modules/observability/main.tf` |
| **Observability — API 5XX alarm** | AWS CloudWatch | `aws_cloudwatch_metric_alarm` | `infra/modules/observability/main.tf` |
| **Observability — Async consumer errors alarm** | AWS CloudWatch | `aws_cloudwatch_metric_alarm` | `infra/modules/observability/main.tf` |
| **Observability — Dashboard** | AWS CloudWatch | `aws_cloudwatch_dashboard` | `infra/modules/observability/main.tf` |
| **Observability — Cost budget** | AWS Budgets | `aws_budgets_budget` | `infra/modules/observability/main.tf` |
| **Bootstrap — Remote state S3** | AWS S3 | `aws_s3_bucket` | `infra/bootstrap/main.tf` |
| **Bootstrap — State versioning** | AWS S3 | `aws_s3_bucket_versioning` | `infra/bootstrap/main.tf` |
| **Bootstrap — State SSE** | AWS S3 | `aws_s3_bucket_server_side_encryption_configuration` | `infra/bootstrap/main.tf` |
| **Bootstrap — Public access block** | AWS S3 | `aws_s3_bucket_public_access_block` | `infra/bootstrap/main.tf` |
| **Bootstrap — DynamoDB lock table** | AWS DynamoDB | `aws_dynamodb_table` | `infra/bootstrap/main.tf` |

## Manual Resources Confirmation

No resources were created manually through the AWS Management Console. All resources listed above are provisioned and managed exclusively through Terraform.

### Terraform State Audit

Run the following command from `infra/` to verify:

```bash
terraform state list
```

The output must contain at minimum one resource from each of the seven required component categories:

| Category | Example Resource | Status |
|---|---|---|
| Compute | `module.compute.aws_lambda_function.this` | ✅ Terraform-managed |
| Storage | `module.storage.aws_s3_bucket.storage` | ✅ Terraform-managed |
| Database | `module.database.aws_dynamodb_table.reservas` | ✅ Terraform-managed |
| Networking | `module.network.aws_apigatewayv2_domain_name.api` | ✅ Terraform-managed |
| Async | `module.async.aws_sqs_queue.main` | ✅ Terraform-managed |
| Security/IAM | `module.iam.aws_iam_role.compute` | ✅ Terraform-managed |
| Observability | `module.observability.aws_cloudwatch_log_group.api` | ✅ Terraform-managed |

### Imported Resources

No resources were imported into Terraform state. All resources were created via `terraform apply` from the initial delivery.

## Deployed Application Components

See `infra/evidence/deployed-components.png` for a screenshot of running application components in the AWS Management Console.
