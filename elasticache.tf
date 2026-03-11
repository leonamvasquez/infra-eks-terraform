# ==============================================================================
# ElastiCache Redis
# ==============================================================================

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-redis-subnet-group"
  subnet_ids = local.private_data_subnet_ids

  tags = { Name = "${local.name_prefix}-redis-subnet-group" }
}

resource "aws_elasticache_parameter_group" "main" {
  name   = "${local.name_prefix}-redis-params"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }

  parameter {
    name  = "notify-keyspace-events"
    value = "Ex"
  }

  tags = { Name = "${local.name_prefix}-redis-params" }
}

# INTENTIONAL_MISCONFIG: HIGH - ElastiCache without transit encryption
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${local.name_prefix}-redis"
  description          = "Redis cluster for ${var.project}"

  engine               = "redis"
  engine_version       = "7.0"
  node_type            = var.redis_node_type
  num_cache_clusters   = var.redis_num_cache_clusters
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.main.name
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.elasticache.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false
  auth_token                 = null

  automatic_failover_enabled = true
  multi_az_enabled           = true

  snapshot_retention_limit = 7
  snapshot_window          = "04:00-05:00"
  maintenance_window       = "sun:06:00-sun:07:00"

  auto_minor_version_upgrade = true

  tags = { Name = "${local.name_prefix}-redis" }
}
