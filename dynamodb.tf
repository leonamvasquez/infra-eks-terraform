# ==============================================================================
# DynamoDB Tables
# ==============================================================================

# --- Sessions Table ---
resource "aws_dynamodb_table" "sessions" {
  name         = "${local.name_prefix}-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  global_secondary_index {
    name            = "user-index"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  # INTENTIONAL_MISCONFIG: HIGH - DynamoDB without point-in-time recovery
  point_in_time_recovery {
    enabled = false
  }

  server_side_encryption {
    enabled = true
  }

  tags = { Name = "${local.name_prefix}-sessions" }
}

# --- Distributed Locks Table ---
resource "aws_dynamodb_table" "locks" {
  name         = "${local.name_prefix}-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "lock_key"

  attribute {
    name = "lock_key"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = { Name = "${local.name_prefix}-locks" }
}

# --- Event Store Table ---
resource "aws_dynamodb_table" "events" {
  name         = "${local.name_prefix}-events"
  billing_mode = "PROVISIONED"
  read_capacity  = 25
  write_capacity = 25
  hash_key     = "aggregate_id"
  range_key    = "event_id"

  attribute {
    name = "aggregate_id"
    type = "S"
  }

  attribute {
    name = "event_id"
    type = "S"
  }

  attribute {
    name = "event_type"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  global_secondary_index {
    name            = "event-type-index"
    hash_key        = "event_type"
    range_key       = "created_at"
    projection_type = "ALL"
    read_capacity   = 10
    write_capacity  = 10
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = { Name = "${local.name_prefix}-events" }
}

# --- DynamoDB Auto Scaling ---
resource "aws_appautoscaling_target" "events_read" {
  max_capacity       = 100
  min_capacity       = 5
  resource_id        = "table/${aws_dynamodb_table.events.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "events_read" {
  name               = "${local.name_prefix}-events-read-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.events_read.resource_id
  scalable_dimension = aws_appautoscaling_target.events_read.scalable_dimension
  service_namespace  = aws_appautoscaling_target.events_read.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_target" "events_write" {
  max_capacity       = 100
  min_capacity       = 5
  resource_id        = "table/${aws_dynamodb_table.events.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "events_write" {
  name               = "${local.name_prefix}-events-write-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.events_write.resource_id
  scalable_dimension = aws_appautoscaling_target.events_write.scalable_dimension
  service_namespace  = aws_appautoscaling_target.events_write.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = 70.0
  }
}
