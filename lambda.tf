# ==============================================================================
# Lambda Functions
# ==============================================================================

# INTENTIONAL_MISCONFIG: HIGH - Lambda functions not in VPC
resource "aws_lambda_function" "main" {
  for_each = local.lambda_functions

  function_name = "${local.name_prefix}-${each.key}"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = each.value.timeout
  memory_size   = each.value.memory_size

  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT     = var.project
      LOG_LEVEL   = "INFO"
    }
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  tags = {
    Name        = "${local.name_prefix}-${each.key}"
    Description = each.value.description
  }
}

data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/lambda_placeholder.zip"

  source {
    content  = "def handler(event, context): return {'statusCode': 200}"
    filename = "index.py"
  }
}

resource "aws_lambda_function_event_invoke_config" "main" {
  for_each = local.lambda_functions

  function_name          = aws_lambda_function.main[each.key].function_name
  maximum_retry_attempts = 2
  qualifier              = "$LATEST"
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.lambda_functions

  name              = "/aws/lambda/${local.name_prefix}-${each.key}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = { Name = "${local.name_prefix}-lambda-${each.key}-logs" }
}

# --- Lambda DLQ ---
resource "aws_sqs_queue" "lambda_dlq" {
  name                       = "${local.name_prefix}-lambda-dlq"
  message_retention_seconds  = 1209600
  kms_master_key_id          = aws_kms_key.sqs.id
  kms_data_key_reuse_period_seconds = 300

  tags = { Name = "${local.name_prefix}-lambda-dlq" }
}

# --- Lambda Permissions for EventBridge ---
resource "aws_lambda_permission" "eventbridge" {
  for_each = local.lambda_functions

  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main[each.key].function_name
  principal     = "events.amazonaws.com"
}

# --- Lambda Provisioned Concurrency for custom-authorizer ---
resource "aws_lambda_provisioned_concurrency_config" "authorizer" {
  function_name                  = aws_lambda_function.main["custom-authorizer"].function_name
  provisioned_concurrent_executions = 5
  qualifier                      = aws_lambda_function.main["custom-authorizer"].version
}
