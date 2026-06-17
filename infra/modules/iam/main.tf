locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Compute Role — API Lambda
# Trust: lambda.amazonaws.com
# Permissions: DynamoDB CRUD (scoped to table), S3 CRUD (scoped to bucket),
#              SQS SendMessage (scoped to queue)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "compute" {
  name = "${local.name_prefix}-compute-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "compute_logs" {
  name = "${local.name_prefix}-compute-logs-policy"
  role = aws_iam_role.compute.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = var.compute_log_group_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "compute_dynamodb" {
  name = "${local.name_prefix}-compute-dynamodb-policy"
  role = aws_iam_role.compute.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "compute_s3" {
  name = "${local.name_prefix}-compute-s3-policy"
  role = aws_iam_role.compute.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.storage_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "compute_sqs" {
  name = "${local.name_prefix}-compute-sqs-policy"
  role = aws_iam_role.compute.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSSendAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = var.async_queue_arn
      }
    ]
  })
}

# KMS decrypt — needed for Secrets Manager integration (D5)
resource "aws_iam_role_policy" "compute_kms" {
  count = var.kms_key_arn != "" ? 1 : 0
  name  = "${local.name_prefix}-compute-kms-policy"
  role  = aws_iam_role.compute.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

# Secrets Manager read — needed for runtime secret retrieval (D5)
resource "aws_iam_role_policy" "compute_secretsmanager" {
  count = var.secret_arn != "" ? 1 : 0
  name  = "${local.name_prefix}-compute-secretsmanager-policy"
  role  = aws_iam_role.compute.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secret_arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Async Consumer Role — SQS-triggered Lambda
# Trust: lambda.amazonaws.com
# Permissions: SQS consume (scoped to queue), S3 PutObject (scoped to bucket)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "async_consumer" {
  name = "${local.name_prefix}-async-consumer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "async_consumer_logs" {
  name = "${local.name_prefix}-async-consumer-logs-policy"
  role = aws_iam_role.async_consumer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = var.async_consumer_log_group_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "async_consumer_sqs" {
  name = "${local.name_prefix}-async-consumer-sqs-policy"
  role = aws_iam_role.async_consumer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSConsumeAccess"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.async_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "async_consumer_s3" {
  name = "${local.name_prefix}-async-consumer-s3-policy"
  role = aws_iam_role.async_consumer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3PutAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${var.storage_bucket_arn}/*"
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# CI Runner Role — GitHub Actions OIDC
# Trust: OIDC federation (set up in Deliverable C)
# Permissions: minimum for terraform plan/apply
# ---------------------------------------------------------------------------
resource "aws_iam_role" "ci_runner" {
  name = "${local.name_prefix}-ci-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = var.oidc_provider_arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "ci_runner_terraform" {
  name = "${local.name_prefix}-ci-runner-policy"
  role = aws_iam_role.ci_runner.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.tfstate_bucket_arn,
          "${var.tfstate_bucket_arn}/*"
        ]
      },
      {
        Sid    = "TerraformLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = var.tflock_table_arn
      },
      {
        Sid    = "TerraformResources"
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:RequestCertificate",
          "acm:DeleteCertificate",
          "acm:AddTagsToCertificate",
          "apigateway:*",
          "budgets:ViewBudget",
          "budgets:ModifyBudget",
          "cloudwatch:*",
          "cloudfront:CreateDistribution",
          "cloudfront:GetDistribution*",
          "cloudfront:UpdateDistribution",
          "cloudfront:DeleteDistribution",
          "cloudfront:TagResource",
          "dynamodb:*",
          "ec2:Describe*",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:DescribeRule",
          "events:PutRule",
          "events:DeleteRule",
          "iam:*",
          "kms:*",
          "lambda:*",
          "logs:*",
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "route53:ListResourceRecordSets",
          "s3:*",
          "secretsmanager:*",
          "scheduler:*",
          "sns:*",
          "sqs:*"
        ]
        Resource = "*"
      }
    ]
  })
}
