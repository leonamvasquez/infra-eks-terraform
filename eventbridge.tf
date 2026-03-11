# ==============================================================================
# EventBridge
# ==============================================================================

# --- Custom Event Bus ---
resource "aws_cloudwatch_event_bus" "main" {
  name = "${local.name_prefix}-events"

  tags = { Name = "${local.name_prefix}-event-bus" }
}

# --- Scheduled Rules ---
resource "aws_cloudwatch_event_rule" "rds_cleanup" {
  name                = "${local.name_prefix}-rds-snapshot-cleanup"
  description         = "Trigger RDS snapshot cleanup Lambda"
  schedule_expression = "rate(24 hours)"
  event_bus_name      = "default"

  tags = { Name = "${local.name_prefix}-rds-cleanup-rule" }
}

resource "aws_cloudwatch_event_target" "rds_cleanup" {
  rule = aws_cloudwatch_event_rule.rds_cleanup.name
  arn  = aws_lambda_function.main["rds-snapshot-cleanup"].arn
}

resource "aws_cloudwatch_event_rule" "s3_events" {
  name           = "${local.name_prefix}-s3-events"
  description    = "Capture S3 events"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.assets.id]
      }
    }
  })

  tags = { Name = "${local.name_prefix}-s3-events-rule" }
}

resource "aws_cloudwatch_event_target" "s3_events" {
  rule = aws_cloudwatch_event_rule.s3_events.name
  arn  = aws_lambda_function.main["s3-event-processor"].arn
}

# --- CloudWatch Alarm State Change ---
resource "aws_cloudwatch_event_rule" "alarm_state" {
  name           = "${local.name_prefix}-alarm-state-change"
  description    = "Capture CloudWatch alarm state changes"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
  })

  tags = { Name = "${local.name_prefix}-alarm-state-rule" }
}

resource "aws_cloudwatch_event_target" "alarm_state" {
  rule = aws_cloudwatch_event_rule.alarm_state.name
  arn  = aws_lambda_function.main["cloudwatch-alarm-handler"].arn
}

# --- ECS/EKS Deployment Events ---
resource "aws_cloudwatch_event_rule" "deployments" {
  name           = "${local.name_prefix}-deployments"
  description    = "Capture deployment events"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      state = ["SUCCEEDED", "FAILED"]
    }
  })

  tags = { Name = "${local.name_prefix}-deployments-rule" }
}

resource "aws_cloudwatch_event_target" "deployments" {
  rule = aws_cloudwatch_event_rule.deployments.name
  arn  = aws_sns_topic.deployments.arn
}

# --- Security Events ---
resource "aws_cloudwatch_event_rule" "security" {
  name           = "${local.name_prefix}-security-events"
  description    = "Capture GuardDuty findings"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })

  tags = { Name = "${local.name_prefix}-security-events-rule" }
}

resource "aws_cloudwatch_event_target" "security" {
  rule = aws_cloudwatch_event_rule.security.name
  arn  = aws_sns_topic.security_alerts.arn
}
