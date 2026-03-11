# ==============================================================================
# AWS Backup
# ==============================================================================

resource "aws_backup_vault" "main" {
  name        = "${local.name_prefix}-vault"
  kms_key_arn = aws_kms_key.s3.arn

  tags = { Name = "${local.name_prefix}-backup-vault" }
}

# INTENTIONAL_MISCONFIG: LOW - Backup vault without lock
resource "aws_backup_plan" "main" {
  name = "${local.name_prefix}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 * * ? *)"

    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn

      lifecycle {
        delete_after = 180
      }
    }
  }

  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * SAT *)"

    lifecycle {
      cold_storage_after = 90
      delete_after       = 730
    }
  }

  tags = { Name = "${local.name_prefix}-backup-plan" }
}

resource "aws_backup_selection" "rds" {
  name         = "${local.name_prefix}-rds-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.main.id

  resources = [
    aws_rds_cluster.main.arn
  ]
}

resource "aws_backup_selection" "dynamodb" {
  name         = "${local.name_prefix}-dynamodb-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.main.id

  resources = [
    aws_dynamodb_table.sessions.arn,
    aws_dynamodb_table.locks.arn,
    aws_dynamodb_table.events.arn,
  ]
}

resource "aws_backup_selection" "ebs" {
  name         = "${local.name_prefix}-ebs-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.main.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}
