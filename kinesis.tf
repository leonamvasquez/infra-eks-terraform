# ==============================================================================
# Kinesis & Firehose
# ==============================================================================

# --- Kinesis Data Stream ---
resource "aws_kinesis_stream" "events" {
  name             = "${local.name_prefix}-events-stream"
  shard_count      = 2
  retention_period = 168

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.sqs.arn

  tags = { Name = "${local.name_prefix}-kinesis-stream" }
}

# --- Firehose for WAF Logs ---
resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  name        = "aws-waf-logs-${local.name_prefix}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.logs.arn
    prefix     = "waf-logs/"

    buffering_size     = 5
    buffering_interval = 300
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = "waf-delivery"
    }
  }

  tags = { Name = "${local.name_prefix}-waf-firehose" }
}

# --- Firehose for Application Logs ---
resource "aws_kinesis_firehose_delivery_stream" "app_logs" {
  name        = "${local.name_prefix}-app-logs"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.events.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.data_lake.arn
    prefix     = "app-logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    buffering_size     = 64
    buffering_interval = 60
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = "app-delivery"
    }
  }

  tags = { Name = "${local.name_prefix}-app-logs-firehose" }
}

resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/firehose/${local.name_prefix}"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = { Name = "${local.name_prefix}-firehose-logs" }
}
