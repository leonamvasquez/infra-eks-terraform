locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
  }

  eks_cluster_name = "${local.name_prefix}-eks"

  # Subnet IDs grouped by type
  public_subnet_ids       = aws_subnet.public[*].id
  private_app_subnet_ids  = aws_subnet.private_app[*].id
  private_data_subnet_ids = aws_subnet.private_data[*].id
  all_private_subnet_ids  = concat(local.private_app_subnet_ids, local.private_data_subnet_ids)

  # OIDC provider URL without https://
  oidc_provider_url = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")

  # ECR repository names
  ecr_repositories = ["api-service", "web-frontend", "worker", "migration", "cron-jobs"]

  # Lambda function definitions
  lambda_functions = {
    rds-snapshot-cleanup = {
      description = "Cleanup old RDS snapshots"
      timeout     = 120
      memory_size = 256
    }
    s3-event-processor = {
      description = "Process S3 event notifications"
      timeout     = 60
      memory_size = 512
    }
    cloudwatch-alarm-handler = {
      description = "Handle CloudWatch alarm state changes"
      timeout     = 30
      memory_size = 128
    }
    custom-authorizer = {
      description = "API Gateway custom authorizer"
      timeout     = 900 # INTENTIONAL_MISCONFIG: HIGH - Lambda with excessive timeout
      memory_size = 128
    }
  }
}
