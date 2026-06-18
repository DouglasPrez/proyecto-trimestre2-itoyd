# Delivery 5 — Security, Observability & One-Click Deployment

## SportSpace — Sistema de Reservas de Canchas Deportivas

| | |
|---|---|
| **Equipo** | Douglas Perez · Carlos Daniel Martinez · Ana Isabel Perez |
| **Entrega** | Delivery 5 de 5 — Security, Observability & One-Click Deployment |
| **Track** | Serverless-Only (skipped Deliverable G — EKS) |
| **Tag** | `oyd-delivery-5` |

---

## 1. IAM and Secrets Design

### IAM Module Role Structure (`infra/modules/iam/`)

The IAM module replaces all ad-hoc inline roles from prior deliveries with four explicitly scoped roles:

| Role | Trust | Actions | Resources |
|---|---|---|---|
| **compute** | `lambda.amazonaws.com` | `dynamodb:Get/Put/Update/Delete/Scan/Query`, `s3:Put/Get/DeleteObject`, `sqs:SendMessage`, `logs:CreateLog*`/`PutLogEvents`, `kms:Decrypt`/`GenerateDataKey`, `secretsmanager:GetSecretValue` | DynamoDB table ARN (incl. indexes), S3 bucket ARN (`/*`), SQS queue ARN, Lambda log group ARN, KMS key ARN, Secret ARN |
| **async-consumer** | `lambda.amazonaws.com` | `sqs:ReceiveMessage`/`DeleteMessage`/`GetQueueAttributes`, `s3:PutObject`, `logs:CreateLog*`/`PutLogEvents` | SQS queue ARN, S3 bucket ARN (`/*`), Lambda log group ARN |
| **ci-runner** | `token.actions.githubusercontent.com` (OIDC) | Terraform plan/apply permissions across all services | Scoped state bucket and lock table; wildcard resource for TF-managed services |
| **scheduler** | `scheduler.amazonaws.com` | `lambda:InvokeFunction` | Specific API Lambda function ARN |

**What changed from prior deliveries:**
- Delivery 1-4: Inline IAM roles and policies defined inside each module (`modules/compute/`, `modules/scheduler/`)
- Delivery 5: A centralized `infra/modules/iam/` module creates all roles. The compute and async consumer modules receive role ARNs as input variables instead of creating their own.
- Exception: the scheduler role remains in `modules/scheduler/` due to a circular dependency (the scheduler role needs the compute Lambda ARN to scope its invoke policy, while the compute module needs the IAM role ARN from the module). This is documented as an architectural trade-off.

### Secrets Manager Runtime Retrieval

The compute module now injects `SECRET_ARN` (instead of `SECRET_KEY` value) as an environment variable to both Lambda functions. At cold start, the handler (`src/index.py`) calls `secretsmanager.get_secret_value(SecretId=SECRET_ARN)` to retrieve the JWT signing key. The secret value is stored in the handler's module-level `SECRET_KEY` variable for the lifetime of the Lambda execution context.

**SDK call:** `boto3.client("secretsmanager").get_secret_value(SecretId=SECRET_ARN)["SecretString"]`

**Why `TF_VAR_secret_key` was retired:**
- The secret value was previously injected as a plaintext environment variable via `TF_VAR_secret_key`
- This exposed the signing key in the Lambda environment variables console and in Terraform state
- With Secrets Manager, only the secret ARN (non-sensitive) is in the environment; the actual key is retrieved at runtime via a scoped API call

---

## 2. KMS Key Management

| Property | Value |
|---|---|
| **Alias** | `alias/sportspace-cmk` |
| **Key ID** | `aws_kms_key.main` (provisioned in `infra/main.tf`) |
| **Rotation** | Enabled (automatic annual rotation) |
| **Deletion window** | 7 days |

### Resources Encrypted with the CMK

| Resource | Previous Encryption | Current Encryption |
|---|---|---|
| S3 storage bucket (vouchers) | SSE-S3 (AES256) | `aws:kms` referencing `alias/sportspace-cmk` |
| DynamoDB reservas table | AWS-managed key (SSE) | Customer-managed KMS key (`kms_key_arn`) |
| Secrets Manager JWT secret | Default encryption key | KMS CMK (`kms_key_id = aws_kms_key.main.arn`) |

### Key Policy

The KMS key policy restricts usage to three principals:
1. **Root account** — administrative IAM operations (`kms:*`)
2. **Compute execution role** — `kms:Decrypt` and `kms:GenerateDataKey` only, scoped to `arn:aws:iam::<account>:role/proyecto-trimestre2-<env>-compute-role`
3. **Secrets Manager service** — `kms:Encrypt`, `kms:Decrypt`, `kms:GenerateDataKey` via `kms:ViaService` condition on `secretsmanager.<region>.amazonaws.com`

No `kms:*` or `kms:Decrypt` wildcard is granted to any principal other than the root account.

**ARN:** `arn:aws:kms:us-east-1:<account>:key/<key-id>` (obtainable via `terraform output kms_key_arn`)

---

## 3. OIDC Federation

### OIDC Provider

| Resource | Value |
|---|---|
| **Provider URL** | `https://token.actions.githubusercontent.com` |
| **Audience** | `sts.amazonaws.com` |
| **Terraform resource** | `aws_iam_openid_connect_provider.github` in `infra/main.tf` |

### Trust Policy Condition

The CI runner role (`proyecto-trimestre2-<env>-ci-runner-role`) trust policy is scoped with:

```
Condition = {
  StringEquals = {
    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
  }
  StringLike = {
    "token.actions.githubusercontent.com:sub" = "repo:itoyd/proyecto-trimestre2-itoyd:*"
  }
}
```

This restricts role assumption to workflows running in the `itoyd/proyecto-trimestre2-itoyd` repository. The `:*` suffix covers all branches and pull requests. A PR-triggered run on a forked repository cannot assume this role.

### Workflow Updates

All four workflow files were updated:
- `pr-plan.yml`: replaced `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` env vars with `aws-actions/configure-aws-credentials@v4` using `role-to-assume: ${{ secrets.CI_RUNNER_ROLE_ARN }}`
- `cd-apply.yml`: same replacement (both dev and staging jobs)
- `destroy.yml`: same replacement
- `drift-detection.yml`: same replacement

The `TF_VAR_secret_key` env var was removed from all workflows (migrated to Secrets Manager).

### Long-Lived Credential Removal

`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `DEV_SECRET_KEY`/`STAGING_SECRET_KEY` were deleted from GitHub repository Secrets. The only remaining secret is `CI_RUNNER_ROLE_ARN`, which is the ARN of the OIDC-assumable CI role output by Terraform.

---

## 4. Observability Design

### Log Groups

| Log Group | Resource | Retention |
|---|---|---|
| `/aws/lambda/proyecto-trimestre2-<env>-api` | `aws_cloudwatch_log_group.api` | `var.log_retention_days` (default: 14) |
| `/aws/lambda/proyecto-trimestre2-<env>-async-consumer` | `aws_cloudwatch_log_group.async_consumer` | `var.log_retention_days` (default: 14) |

### Metric Alarms

| Alarm | Metric | Namespace | Threshold | Period | Evaluation Periods | Why this value |
|---|---|---|---|---|---|---|
| **API 5XX errors** | `5xxError` (Sum) | AWS/ApiGateway | > 5 | 300s | 2 | In a healthy API, 5XX errors should be near zero. A threshold of 5 in two consecutive 5-minute windows indicates a persistent problem worth investigating. |
| **Async consumer errors** | Errors (Sum) | AWS/Lambda | > 0 | 300s | 2 | The async consumer should process messages without errors. Any error in 2 consecutive periods requires immediate investigation. |

Both alarms are wired to an SNS topic with an email subscription targeting `var.notification_email`.

### Dashboard Widgets

The CloudWatch dashboard (`proyecto-trimestre2-<env>-dashboard`) includes three widgets generated via `jsonencode()`:

1. **Request Count** — sum of API Gateway `Count` metric over 5-minute periods
2. **Error Rate** — Lambda `Errors` metric for both the API and async consumer functions
3. **Average Latency** — API Gateway `Latency` metric averaged over 5-minute periods

All metric names, namespaces, and dimensions reference Terraform variables or locals — no hardcoded metric names.

### Cost Budget

| Parameter | Value |
|---|---|
| **Monthly limit** | `var.monthly_budget_usd` (default: $50 USD) |
| **Notification threshold** | 80% of limit → `$40 USD` |
| **Notification target** | SNS topic (same as alarms) |
| **Terraform resource** | `aws_budgets_budget.monthly` in `infra/modules/observability/main.tf` |

---

## 5. Two Architectural Trade-offs

### Trade-off 1 — Scheduler Role Remains in Its Own Module

**Decision:** The scheduler IAM role was not extracted to the centralized IAM module and instead remains defined in `infra/modules/scheduler/main.tf`.

**Justification:** The scheduler role requires its invoke policy to be scoped to the specific compute Lambda function ARN (`lambda:InvokeFunction` on `module.compute.function_arn`). If the scheduler role were in the centralized IAM module, the IAM module would need to receive the compute function ARN as an input variable. But the compute module needs the IAM module's execution role ARN as an input — creating a circular dependency (IAM module → compute function ARN → IAM module role ARN). Keeping the scheduler role in its own module breaks this cycle because the scheduler module depends on the compute module (for the function ARN) but not vice versa. The scheduler role is a single-policy role with minimal complexity, so the duplication is acceptable. The IAM module still handles the three most complex roles (compute, async consumer, CI runner).

### Trade-off 2 — Single Shared KMS CMK vs. Per-Service Keys

**Decision:** A single shared KMS CMK (`alias/sportspace-cmk`) encrypts the S3 bucket, DynamoDB table, and Secrets Manager secret.

**Justification:** Using a single CMK simplifies key management — one key policy, one alias, one rotation schedule. The key policy is already scoped to restrict usage: only the compute execution role (for Decrypt) and the Secrets Manager service principal (via `kms:ViaService`) can use it. Per-service keys would provide slightly stronger isolation (e.g., compromise of the compute role would not expose DynamoDB data at rest), but the additional complexity of managing 3 keys with separate policies, aliases, and rotation is not justified for an MVP with a $50/month budget. If the application grows and regulatory requirements demand separation of cryptographic boundaries (e.g., PCI DSS), migrating to per-service keys would be straightforward — each service would get its own `aws_kms_key` resource, and the IAM module's compute role policy would reference the new key ARN.

---

## Evidence Index

See `infra/README.md` under the **## Evidence — Delivery 5** section for all evidence files.
