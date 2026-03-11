# ==============================================================================
# RDS Aurora PostgreSQL
# ==============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = local.private_data_subnet_ids

  tags = { Name = "${local.name_prefix}-db-subnet-group" }
}

resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${local.name_prefix}-aurora-pg-params"
  family      = "aurora-postgresql15"
  description = "Aurora PostgreSQL cluster parameter group"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = { Name = "${local.name_prefix}-aurora-pg-params" }
}

resource "aws_db_parameter_group" "main" {
  name        = "${local.name_prefix}-aurora-pg-instance-params"
  family      = "aurora-postgresql15"
  description = "Aurora PostgreSQL instance parameter group"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,pgaudit"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  tags = { Name = "${local.name_prefix}-aurora-pg-instance-params" }
}

# INTENTIONAL_MISCONFIG: CRITICAL - RDS without encryption at rest
resource "aws_rds_cluster" "main" {
  cluster_identifier = "${local.name_prefix}-aurora"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"
  engine_mode        = "provisioned"

  database_name   = var.rds_database_name
  master_username = var.rds_master_username
  master_password = random_password.rds_master.result

  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name

  storage_encrypted = false
  # kms_key_id      = aws_kms_key.rds.arn  # Intentionally omitted

  backup_retention_period      = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"

  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${local.name_prefix}-aurora-final"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 16
  }

  tags = { Name = "${local.name_prefix}-aurora-cluster" }
}

resource "aws_rds_cluster_instance" "main" {
  count = 2

  identifier           = "${local.name_prefix}-aurora-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.main.engine
  engine_version       = aws_rds_cluster.main.engine_version
  db_parameter_group_name = aws_db_parameter_group.main.name

  # INTENTIONAL_MISCONFIG: HIGH - RDS instance without enhanced monitoring
  monitoring_interval = 0

  auto_minor_version_upgrade = true
  publicly_accessible        = false

  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  tags = { Name = "${local.name_prefix}-aurora-${count.index + 1}" }
}

# --- RDS Proxy ---
resource "aws_db_proxy" "main" {
  name                   = "${local.name_prefix}-rds-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_security_group_ids = [aws_security_group.rds.id]
  vpc_subnet_ids         = local.private_data_subnet_ids

  auth {
    auth_scheme = "SECRETS"
    description = "RDS proxy auth"
    iam_auth    = "REQUIRED"
    secret_arn  = aws_secretsmanager_secret.rds_credentials.arn
  }

  tags = { Name = "${local.name_prefix}-rds-proxy" }
}

resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "main" {
  db_proxy_name         = aws_db_proxy.main.name
  target_group_name     = aws_db_proxy_default_target_group.main.name
  db_cluster_identifier = aws_rds_cluster.main.id
}

resource "aws_iam_role" "rds_proxy" {
  name = "${local.name_prefix}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-rds-proxy-role" }
}

resource "aws_iam_role_policy" "rds_proxy" {
  name = "${local.name_prefix}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.rds_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.secrets.arn
      }
    ]
  })
}
