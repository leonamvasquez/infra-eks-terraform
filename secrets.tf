# ==============================================================================
# Secrets Manager
# ==============================================================================

resource "aws_secretsmanager_secret" "rds_credentials" {
  name       = "${local.name_prefix}/rds/master-credentials"
  kms_key_id = aws_kms_key.secrets.arn

  tags = { Name = "${local.name_prefix}-rds-credentials" }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.rds_master_username
    password = random_password.rds_master.result
    engine   = "aurora-postgresql"
    host     = aws_rds_cluster.main.endpoint
    port     = 5432
    dbname   = var.rds_database_name
  })
}

resource "aws_secretsmanager_secret" "api_keys" {
  name       = "${local.name_prefix}/api/keys"
  kms_key_id = aws_kms_key.secrets.arn

  tags = { Name = "${local.name_prefix}-api-keys" }
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    stripe_key     = "sk_placeholder_replace_me"
    sendgrid_key   = "SG.placeholder_replace_me"
    datadog_api_key = "placeholder_replace_me"
  })
}

resource "aws_secretsmanager_secret" "redis_auth" {
  name       = "${local.name_prefix}/redis/auth-token"
  kms_key_id = aws_kms_key.secrets.arn

  tags = { Name = "${local.name_prefix}-redis-auth" }
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = random_password.redis_auth.result
}

resource "aws_secretsmanager_secret" "tls_certificates" {
  name       = "${local.name_prefix}/tls/certificates"
  kms_key_id = aws_kms_key.secrets.arn

  tags = { Name = "${local.name_prefix}-tls-certificates" }
}

resource "aws_secretsmanager_secret_version" "tls_certificates" {
  secret_id = aws_secretsmanager_secret.tls_certificates.id
  secret_string = jsonencode({
    private_key = "placeholder"
    certificate = "placeholder"
    ca_bundle   = "placeholder"
  })
}

# INTENTIONAL_MISCONFIG: MEDIUM - Secret without rotation configuration
resource "aws_secretsmanager_secret" "external_service" {
  name        = "${local.name_prefix}/external/service-credentials"
  description = "External service credentials without rotation"

  tags = { Name = "${local.name_prefix}-external-service" }
}

resource "aws_secretsmanager_secret_version" "external_service" {
  secret_id = aws_secretsmanager_secret.external_service.id
  secret_string = jsonencode({
    api_key    = "placeholder"
    api_secret = "placeholder"
  })
}
