# ==============================================================================
# Systems Manager
# ==============================================================================

# --- SSM Parameters ---
resource "aws_ssm_parameter" "database_endpoint" {
  name  = "/${local.name_prefix}/database/endpoint"
  type  = "String"
  value = aws_rds_cluster.main.endpoint

  tags = { Name = "${local.name_prefix}-db-endpoint" }
}

resource "aws_ssm_parameter" "database_reader_endpoint" {
  name  = "/${local.name_prefix}/database/reader-endpoint"
  type  = "String"
  value = aws_rds_cluster.main.reader_endpoint

  tags = { Name = "${local.name_prefix}-db-reader-endpoint" }
}

resource "aws_ssm_parameter" "redis_endpoint" {
  name  = "/${local.name_prefix}/redis/endpoint"
  type  = "String"
  value = aws_elasticache_replication_group.main.primary_endpoint_address

  tags = { Name = "${local.name_prefix}-redis-endpoint" }
}

resource "aws_ssm_parameter" "opensearch_endpoint" {
  name  = "/${local.name_prefix}/opensearch/endpoint"
  type  = "String"
  value = aws_opensearch_domain.main.endpoint

  tags = { Name = "${local.name_prefix}-opensearch-endpoint" }
}

resource "aws_ssm_parameter" "eks_cluster_name" {
  name  = "/${local.name_prefix}/eks/cluster-name"
  type  = "String"
  value = local.eks_cluster_name

  tags = { Name = "${local.name_prefix}-eks-cluster-name" }
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${local.name_prefix}/network/vpc-id"
  type  = "String"
  value = aws_vpc.main.id

  tags = { Name = "${local.name_prefix}-vpc-id" }
}

# INTENTIONAL_MISCONFIG: LOW - SSM parameter with plain text secret
resource "aws_ssm_parameter" "api_endpoint" {
  name  = "/${local.name_prefix}/api/internal-key"
  type  = "String"
  value = "sk-internal-placeholder-key-12345"

  tags = { Name = "${local.name_prefix}-api-internal-key" }
}

# --- Maintenance Window ---
resource "aws_ssm_maintenance_window" "main" {
  name                       = "${local.name_prefix}-maintenance"
  schedule                   = "cron(0 4 ? * SUN *)"
  duration                   = 3
  cutoff                     = 1
  allow_unassociated_targets = true

  tags = { Name = "${local.name_prefix}-maintenance-window" }
}

resource "aws_ssm_maintenance_window_target" "bastion" {
  window_id     = aws_ssm_maintenance_window.main.id
  name          = "bastion-targets"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Name"
    values = ["${local.name_prefix}-bastion"]
  }
}

resource "aws_ssm_maintenance_window_task" "patch" {
  window_id       = aws_ssm_maintenance_window.main.id
  name            = "patch-instances"
  task_type       = "RUN_COMMAND"
  task_arn        = "AWS-RunPatchBaseline"
  priority        = 1
  max_concurrency = "50%"
  max_errors      = "25%"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.bastion.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      timeout_seconds = 600

      parameter {
        name   = "Operation"
        values = ["Install"]
      }
    }
  }
}
