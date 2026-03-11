# ==============================================================================
# KMS Keys
# ==============================================================================

# --- EKS Secrets Encryption Key ---
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${local.name_prefix}-eks-kms" }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.name_prefix}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# --- RDS Encryption Key ---
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${local.name_prefix}-rds-kms" }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name_prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# --- S3 Encryption Key ---
# INTENTIONAL_MISCONFIG: CRITICAL - KMS key without rotation
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = false

  tags = { Name = "${local.name_prefix}-s3-kms" }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${local.name_prefix}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# --- EBS Encryption Key ---
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS volume encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${local.name_prefix}-ebs-kms" }
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${local.name_prefix}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# --- CloudWatch Logs Encryption Key ---
resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = { Name = "${local.name_prefix}-cloudwatch-kms" }
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/${local.name_prefix}-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

# --- Secrets Manager Encryption Key ---
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${local.name_prefix}-secrets-kms" }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# --- SQS Encryption Key ---
resource "aws_kms_key" "sqs" {
  description             = "KMS key for SQS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${local.name_prefix}-sqs-kms" }
}

resource "aws_kms_alias" "sqs" {
  name          = "alias/${local.name_prefix}-sqs"
  target_key_id = aws_kms_key.sqs.key_id
}

# --- SNS Encryption Key ---
resource "aws_kms_key" "sns" {
  description             = "KMS key for SNS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${local.name_prefix}-sns-kms" }
}

resource "aws_kms_alias" "sns" {
  name          = "alias/${local.name_prefix}-sns"
  target_key_id = aws_kms_key.sns.key_id
}
