# ==============================================================================
# Terraform Variables — Production
# ==============================================================================

# --- Core ---
project     = "enterprise"
environment = "prod"
owner       = "platform-team"
cost_center = "engineering"
aws_region  = "us-east-1"

# --- Networking ---
vpc_cidr = "10.0.0.0/16"

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_app_subnet_cidrs = [
  "10.0.10.0/24",
  "10.0.11.0/24"
]

private_data_subnet_cidrs = [
  "10.0.20.0/24",
  "10.0.21.0/24"
]

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

# --- EKS ---
eks_cluster_version       = "1.28"
eks_system_instance_types = ["m6i.large"]
eks_app_instance_types    = ["m6i.xlarge", "m5.xlarge"]
eks_gpu_instance_types    = ["g5.xlarge"]

eks_system_desired_size = 2
eks_app_desired_size    = 3
eks_gpu_desired_size    = 0

# --- Database ---
rds_master_username = "dbadmin"
rds_database_name   = "enterprise"

redis_node_type          = "cache.r6g.large"
redis_num_cache_clusters = 2

opensearch_instance_type  = "r6g.large.search"
opensearch_instance_count = 2

# --- Domain ---
domain_name = "enterprise-platform.example.com"

# --- Bastion ---
bastion_instance_type = "t3.micro"

# --- Observability ---
enable_container_insights = true

# --- Backup ---
backup_retention_days = 30
