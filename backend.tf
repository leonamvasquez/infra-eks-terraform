# ==============================================================================
# Remote Backend — S3 with Native State Locking
# ==============================================================================
# Armazena o state no S3 com lock nativo via S3 (sem DynamoDB).
# Requer Terraform >= 1.10 e versionamento habilitado no bucket.
#
# Pré-requisitos (criar manualmente ou via bootstrap):
#   1. Bucket S3:  terraform-state-<ACCOUNT_ID> (com versionamento habilitado)
#
# Os valores são configuráveis via -backend-config na pipeline:
#   terraform init \
#     -backend-config="bucket=terraform-state-123456789012"
# ==============================================================================

terraform {
  backend "s3" {
    bucket       = "terraform-state-placeholder"
    key          = "eks-infrastructure/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
