# ==============================================================================
# OpenSearch Domain
# ==============================================================================

resource "aws_opensearch_domain" "main" {
  domain_name    = "${local.name_prefix}-search"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type            = var.opensearch_instance_type
    instance_count           = var.opensearch_instance_count
    zone_awareness_enabled   = true
    dedicated_master_enabled = true
    dedicated_master_type    = "m6g.large.search"
    dedicated_master_count   = 3

    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 100
    iops        = 3000
    throughput  = 125
  }

  vpc_options {
    subnet_ids         = slice(local.private_data_subnet_ids, 0, 2)
    security_group_ids = [aws_security_group.opensearch.id]
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.s3.arn
  }

  # INTENTIONAL_MISCONFIG: HIGH - OpenSearch without node-to-node encryption
  node_to_node_encryption {
    enabled = false
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = random_password.rds_master.result
    }
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_slow.arn
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_index.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch_error.arn
    log_type                 = "ES_APPLICATION_LOGS"
  }

  auto_tune_options {
    desired_state       = "ENABLED"
    rollback_on_disable = "NO_ROLLBACK"
  }

  tags = { Name = "${local.name_prefix}-opensearch" }
}

resource "aws_cloudwatch_log_group" "opensearch_slow" {
  name              = "/aws/opensearch/${local.name_prefix}/slow-logs"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = { Name = "${local.name_prefix}-opensearch-slow-logs" }
}

resource "aws_cloudwatch_log_group" "opensearch_index" {
  name              = "/aws/opensearch/${local.name_prefix}/index-logs"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = { Name = "${local.name_prefix}-opensearch-index-logs" }
}

resource "aws_cloudwatch_log_group" "opensearch_error" {
  name              = "/aws/opensearch/${local.name_prefix}/error-logs"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = { Name = "${local.name_prefix}-opensearch-error-logs" }
}

resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  policy_name = "${local.name_prefix}-opensearch-log-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "es.amazonaws.com"
      }
      Action = [
        "logs:PutLogEvents",
        "logs:PutLogEventsBatch",
        "logs:CreateLogStream"
      ]
      Resource = "arn:${data.aws_partition.current.partition}:logs:*"
    }]
  })
}
