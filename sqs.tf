# ==============================================================================
# SQS Queues
# ==============================================================================

# --- Main Processing Queue ---
resource "aws_sqs_queue" "processing" {
  name                       = "${local.name_prefix}-processing"
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 300

  kms_master_key_id                 = aws_kms_key.sqs.id
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.processing_dlq.arn
    maxReceiveCount     = 5
  })

  tags = { Name = "${local.name_prefix}-processing-queue" }
}

resource "aws_sqs_queue" "processing_dlq" {
  name                      = "${local.name_prefix}-processing-dlq"
  message_retention_seconds = 1209600

  kms_master_key_id                 = aws_kms_key.sqs.id
  kms_data_key_reuse_period_seconds = 300

  tags = { Name = "${local.name_prefix}-processing-dlq" }
}

# --- Notification Queue ---
resource "aws_sqs_queue" "notifications" {
  name                       = "${local.name_prefix}-notifications"
  delay_seconds              = 0
  max_message_size           = 65536
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 60

  kms_master_key_id                 = aws_kms_key.sqs.id
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = 3
  })

  tags = { Name = "${local.name_prefix}-notifications-queue" }
}

resource "aws_sqs_queue" "notifications_dlq" {
  name                      = "${local.name_prefix}-notifications-dlq"
  message_retention_seconds = 1209600

  kms_master_key_id                 = aws_kms_key.sqs.id
  kms_data_key_reuse_period_seconds = 300

  tags = { Name = "${local.name_prefix}-notifications-dlq" }
}

# --- FIFO Queue for Ordered Processing ---
resource "aws_sqs_queue" "ordered" {
  name                        = "${local.name_prefix}-ordered.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"

  kms_master_key_id                 = aws_kms_key.sqs.id
  kms_data_key_reuse_period_seconds = 300

  tags = { Name = "${local.name_prefix}-ordered-queue" }
}

# --- SQS Queue Policies ---
resource "aws_sqs_queue_policy" "processing" {
  queue_url = aws_sqs_queue.processing.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowSNSPublish"
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.processing.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.events.arn
        }
      }
    }]
  })
}
