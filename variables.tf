# ==============================================================================
# Core Variables
# ==============================================================================

variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "enterprise-platform"
}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "Environment must be prod, staging, or dev."
  }
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Team or individual owning this infrastructure"
  type        = string
  default     = "platform-engineering"
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "CC-PLATFORM-001"
}

# ==============================================================================
# Networking Variables
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for private data subnets"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

# ==============================================================================
# EKS Variables
# ==============================================================================

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_system_instance_types" {
  description = "Instance types for system node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_app_instance_types" {
  description = "Instance types for application node group"
  type        = list(string)
  default     = ["m5.xlarge"]
}

variable "eks_gpu_instance_types" {
  description = "Instance types for GPU node group"
  type        = list(string)
  default     = ["g4dn.xlarge"]
}

variable "eks_system_desired_size" {
  description = "Desired number of system nodes"
  type        = number
  default     = 2
}

variable "eks_app_desired_size" {
  description = "Desired number of app nodes"
  type        = number
  default     = 3
}

variable "eks_gpu_desired_size" {
  description = "Desired number of GPU nodes"
  type        = number
  default     = 1
}

# ==============================================================================
# Database Variables
# ==============================================================================

variable "rds_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6g.xlarge"
}

variable "rds_database_name" {
  description = "Name of the default database"
  type        = string
  default     = "platform"
}

variable "rds_master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "dbadmin"
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_num_cache_clusters" {
  description = "Number of Redis cache clusters"
  type        = number
  default     = 3
}

variable "opensearch_instance_type" {
  description = "OpenSearch instance type"
  type        = string
  default     = "r6g.large.search"
}

variable "opensearch_instance_count" {
  description = "Number of OpenSearch data nodes"
  type        = number
  default     = 2
}

variable "opensearch_master_instance_type" {
  description = "OpenSearch dedicated master instance type"
  type        = string
  default     = "r6g.large.search"
}

variable "opensearch_volume_size" {
  description = "OpenSearch EBS volume size in GB"
  type        = number
  default     = 100
}

# ==============================================================================
# Domain & Certificate Variables
# ==============================================================================

variable "domain_name" {
  description = "Primary domain name"
  type        = string
  default     = "platform.example.com"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID (use placeholder for testing)"
  type        = string
  default     = "Z0000000000000000000"
}

# ==============================================================================
# Lambda Variables
# ==============================================================================

variable "lambda_runtime" {
  description = "Default Lambda runtime"
  type        = string
  default     = "python3.11"
}

# ==============================================================================
# Bastion Variables
# ==============================================================================

variable "bastion_instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

# ==============================================================================
# Observability Variables
# ==============================================================================

variable "enable_container_insights" {
  description = "Enable EKS Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "alarm_email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
  default     = "ops@example.com"
}

# ==============================================================================
# Backup Variables
# ==============================================================================

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 35
}

# ==============================================================================
# API Gateway Variables
# ==============================================================================

variable "api_gateway_stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "v1"
}
