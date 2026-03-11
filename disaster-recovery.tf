# ==============================================================================
# Disaster Recovery
# ==============================================================================

# --- DR Backup Vault (secondary region) ---
resource "aws_backup_vault" "dr" {
  provider    = aws.us_east_1
  name        = "${local.name_prefix}-dr-vault"
  kms_key_arn = aws_kms_key.dr.arn

  tags = { Name = "${local.name_prefix}-dr-vault" }
}

resource "aws_kms_key" "dr" {
  provider                = aws.us_east_1
  description             = "KMS key for DR backup vault"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "${local.name_prefix}-dr-kms" }
}

# --- S3 Cross-Region Replication ---
resource "aws_s3_bucket" "backups_replica" {
  provider = aws.us_east_1
  bucket   = "${local.name_prefix}-backups-replica-${data.aws_caller_identity.current.account_id}"

  tags = { Name = "${local.name_prefix}-backups-replica" }
}

resource "aws_s3_bucket_versioning" "backups_replica" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.backups_replica.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups_replica" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.backups_replica.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.dr.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups_replica" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.backups_replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "replication" {
  name = "${local.name_prefix}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-s3-replication-role" }
}

resource "aws_iam_role_policy" "replication" {
  name = "${local.name_prefix}-s3-replication-policy"
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.backups.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.backups.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.backups_replica.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "backups" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.backups_replica.arn
      storage_class = "STANDARD_IA"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.dr.arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.backups]
}

# --- Route53 Failover Records ---
resource "aws_route53_record" "primary_failover" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "service.${var.domain_name}"
  type    = "A"

  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.api.id
}
