# ==============================================================================
# Observability (X-Ray, Prometheus, Grafana, Synthetics)
# ==============================================================================

# --- X-Ray Sampling Rules ---
resource "aws_xray_sampling_rule" "main" {
  rule_name      = "${local.name_prefix}-default"
  priority       = 1000
  version        = 1
  reservoir_size = 5
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  tags = { Name = "${local.name_prefix}-xray-sampling" }
}

resource "aws_xray_sampling_rule" "health_checks" {
  rule_name      = "${local.name_prefix}-health-checks"
  priority       = 100
  version        = 1
  reservoir_size = 0
  fixed_rate     = 0.0
  url_path       = "/health*"
  host           = "*"
  http_method    = "GET"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  tags = { Name = "${local.name_prefix}-xray-health-sampling" }
}

resource "aws_xray_group" "main" {
  group_name        = "${local.name_prefix}-errors"
  filter_expression = "responsetime > 5 OR fault = true"

  tags = { Name = "${local.name_prefix}-xray-error-group" }
}

# --- Amazon Managed Prometheus ---
resource "aws_prometheus_workspace" "main" {
  alias = "${local.name_prefix}-prometheus"

  tags = { Name = "${local.name_prefix}-prometheus" }
}

resource "aws_prometheus_rule_group_namespace" "main" {
  name         = "default"
  workspace_id = aws_prometheus_workspace.main.id

  data = <<-EOF
    groups:
      - name: node-alerts
        rules:
          - alert: HighCPUUsage
            expr: node_cpu_utilization > 80
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "High CPU usage detected"
          - alert: HighMemoryUsage
            expr: node_memory_utilization > 85
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "High memory usage detected"
          - alert: PodCrashLooping
            expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Pod is crash looping"
  EOF
}

# --- Amazon Managed Grafana ---
resource "aws_grafana_workspace" "main" {
  name                     = "${local.name_prefix}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn

  data_sources = ["PROMETHEUS", "CLOUDWATCH", "XRAY"]

  configuration = jsonencode({
    plugins = {
      pluginAdminEnabled = true
    }
    unifiedAlerting = {
      enabled = true
    }
  })

  tags = { Name = "${local.name_prefix}-grafana" }
}

resource "aws_iam_role" "grafana" {
  name = "${local.name_prefix}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "grafana.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-grafana-role" }
}

resource "aws_iam_role_policy" "grafana" {
  name = "${local.name_prefix}-grafana-policy"
  role = aws_iam_role.grafana.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:ListWorkspaces",
          "aps:DescribeWorkspace",
          "aps:QueryMetrics",
          "aps:GetLabels",
          "aps:GetSeries",
          "aps:GetMetricMetadata"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetInsightRuleReport"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:BatchGetTraces",
          "xray:GetTraceSummaries",
          "xray:GetTraceGraph",
          "xray:GetGroups",
          "xray:GetGroup",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- CloudWatch Synthetics Canary ---
resource "aws_synthetics_canary" "api_health" {
  name                 = "${local.name_prefix}-api"
  artifact_s3_location = "s3://${aws_s3_bucket.logs.id}/synthetics/"
  execution_role_arn   = aws_iam_role.synthetics.arn
  handler              = "apiCanaryBlueprint.handler"
  zip_file             = data.archive_file.canary_placeholder.output_path
  runtime_version      = "syn-nodejs-puppeteer-6.2"
  start_canary         = true

  schedule {
    expression = "rate(5 minutes)"
  }

  run_config {
    timeout_in_seconds = 60
    memory_in_mb       = 960
    active_tracing     = true
  }

  tags = { Name = "${local.name_prefix}-api-canary" }
}

data "archive_file" "canary_placeholder" {
  type        = "zip"
  output_path = "${path.module}/canary_placeholder.zip"

  source {
    content  = "const handler = async () => { return 'OK'; }; exports.handler = handler;"
    filename = "nodejs/node_modules/apiCanaryBlueprint.js"
  }
}

resource "aws_iam_role" "synthetics" {
  name = "${local.name_prefix}-synthetics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-synthetics-role" }
}

resource "aws_iam_role_policy" "synthetics" {
  name = "${local.name_prefix}-synthetics-policy"
  role = aws_iam_role.synthetics.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.logs.arn}/synthetics/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "xray:PutTraceSegments"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "CloudWatchSynthetics"
          }
        }
      }
    ]
  })
}
