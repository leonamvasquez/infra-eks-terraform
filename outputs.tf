# ==============================================================================
# Outputs
# ==============================================================================

# --- VPC ---
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = local.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs"
  value       = local.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "Private data subnet IDs"
  value       = local.private_data_subnet_ids
}

# --- EKS ---
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_certificate_authority" {
  description = "EKS cluster CA certificate"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_security_group.eks_cluster.id
}

# --- Database ---
output "rds_cluster_endpoint" {
  description = "RDS Aurora cluster writer endpoint"
  value       = aws_rds_cluster.main.endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "RDS Aurora cluster reader endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint"
  value       = aws_db_proxy.main.endpoint
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = aws_opensearch_domain.main.endpoint
}

# --- Load Balancers ---
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID"
  value       = aws_lb.main.zone_id
}

output "nlb_dns_name" {
  description = "NLB DNS name"
  value       = aws_lb.internal.dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

# --- DNS ---
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "route53_nameservers" {
  description = "Route53 name servers"
  value       = aws_route53_zone.main.name_servers
}

# --- ECR ---
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.main : k => v.repository_url }
}

# --- Secrets ---
output "rds_credentials_secret_arn" {
  description = "RDS credentials secret ARN"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

# --- API Gateway ---
output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.main.invoke_url
}

# --- Monitoring ---
output "prometheus_workspace_endpoint" {
  description = "Managed Prometheus workspace endpoint"
  value       = aws_prometheus_workspace.main.prometheus_endpoint
}

output "grafana_workspace_endpoint" {
  description = "Managed Grafana workspace endpoint"
  value       = aws_grafana_workspace.main.endpoint
}

# --- CI/CD ---
output "codecommit_clone_url_http" {
  description = "CodeCommit HTTPS clone URL"
  value       = aws_codecommit_repository.main.clone_url_http
}

output "codepipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.main.name
}

# --- KMS ---
output "kms_key_arns" {
  description = "KMS key ARNs"
  value = {
    eks        = aws_kms_key.eks.arn
    rds        = aws_kms_key.rds.arn
    s3         = aws_kms_key.s3.arn
    ebs        = aws_kms_key.ebs.arn
    cloudwatch = aws_kms_key.cloudwatch.arn
    secrets    = aws_kms_key.secrets.arn
    sqs        = aws_kms_key.sqs.arn
    sns        = aws_kms_key.sns.arn
  }
}
