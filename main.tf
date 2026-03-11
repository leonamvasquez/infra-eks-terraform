# ==============================================================================
# Enterprise EKS Platform — Production Infrastructure
# ==============================================================================
# Total resources: 348 (+ 19 data sources)
# Services used: 38+
# Intentional misconfigs: 32 (7 CRITICAL, 11 HIGH, 9 MEDIUM, 5 LOW)
# ==============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}

# Random password for RDS
resource "random_password" "rds_master" {
  length  = 32
  special = true
}

# Random password for Redis auth
resource "random_password" "redis_auth" {
  length  = 64
  special = false
}
