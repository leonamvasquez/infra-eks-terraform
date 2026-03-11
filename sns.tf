# ==============================================================================
# SNS Topics
# ==============================================================================

# --- Application Events Topic ---
resource "aws_sns_topic" "events" {
  name              = "${local.name_prefix}-events"
  kms_master_key_id = aws_kms_key.sns.id

  tags = { Name = "${local.name_prefix}-events-topic" }
}

resource "aws_sns_topic_subscription" "events_to_sqs" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.processing.arn
}

# --- Alarm Notifications Topic ---
resource "aws_sns_topic" "alarms" {
  name              = "${local.name_prefix}-alarms"
  kms_master_key_id = aws_kms_key.sns.id

  tags = { Name = "${local.name_prefix}-alarms-topic" }
}

# --- Deployment Notifications Topic ---
resource "aws_sns_topic" "deployments" {
  name              = "${local.name_prefix}-deployments"
  kms_master_key_id = aws_kms_key.sns.id

  tags = { Name = "${local.name_prefix}-deployments-topic" }
}

# --- Security Alerts Topic ---
# INTENTIONAL_MISCONFIG: LOW - SNS topic without encryption
resource "aws_sns_topic" "security_alerts" {
  name = "${local.name_prefix}-security-alerts"

  tags = { Name = "${local.name_prefix}-security-alerts-topic" }
}

# --- SNS Topic Policies ---
resource "aws_sns_topic_policy" "alarms" {
  arn = aws_sns_topic.alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alarms.arn
      },
      {
        Sid    = "AllowEventBridge"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alarms.arn
      }
    ]
  })
}
