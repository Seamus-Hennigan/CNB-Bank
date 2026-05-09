# ── API Gateway Alarms ────────────────────────────────────────────────────────

# Fires when the 5XX error rate exceeds 5 requests over a 5-minute window.
# A sustained spike indicates a backend failure in the banking or trading service.
resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "${var.project_name}-api-5xx-errors"
  alarm_description   = "API Gateway 5XX error rate is elevated — possible backend failure"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ApiName = var.api_gateway_name
  }

  # Alarms are for Grafana dashboard visibility only — no SNS notifications configured.
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  tags = {
    Name        = "${var.project_name}-api-5xx-errors"
    Environment = var.environment
  }
}

# Fires when p99 integration latency exceeds 3 seconds over a 5-minute window.
# High latency indicates the Pi backend is slow to respond through the Cloudflare Tunnel.
resource "aws_cloudwatch_metric_alarm" "api_latency_p99" {
  alarm_name          = "${var.project_name}-api-latency-p99"
  alarm_description   = "API Gateway p99 integration latency > 3s — backend may be under load"
  namespace           = "AWS/ApiGateway"
  metric_name         = "IntegrationLatency"
  extended_statistic  = "p99"
  period              = 300
  evaluation_periods  = 1
  threshold           = 3000
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ApiName = var.api_gateway_name
  }

  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  tags = {
    Name        = "${var.project_name}-api-latency-p99"
    Environment = var.environment
  }
}

# ── WAF Alarms ────────────────────────────────────────────────────────────────

# Fires when WAF blocks more than 100 requests in 5 minutes.
# A sudden spike in blocked requests may indicate an active attack or a misconfigured client.
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "${var.project_name}-waf-blocked-requests"
  alarm_description   = "WAF blocked request rate is elevated — possible attack or misconfiguration"
  namespace           = "AWS/WAFV2"
  metric_name         = "BlockedRequests"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 100
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    WebACL = var.waf_acl_name
    Region = "us-east-1"
    Rule   = "ALL"
  }

  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  tags = {
    Name        = "${var.project_name}-waf-blocked-requests"
    Environment = var.environment
  }
}

# ── S3 Alarms ─────────────────────────────────────────────────────────────────

# Fires when the frontend S3 bucket returns more than 50 4XX errors in 5 minutes.
# This typically means broken asset paths, stale CloudFront cache, or a bad deploy.
resource "aws_cloudwatch_metric_alarm" "s3_4xx_errors" {
  alarm_name          = "${var.project_name}-s3-4xx-errors"
  alarm_description   = "Frontend S3 bucket returning elevated 4XX errors — check for broken asset paths"
  namespace           = "AWS/S3"
  metric_name         = "4xxErrors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 50
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    BucketName = var.s3_bucket_name
    FilterId   = "EntireBucket"
  }

  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  tags = {
    Name        = "${var.project_name}-s3-4xx-errors"
    Environment = var.environment
  }
}

# ── Billing Alarm ─────────────────────────────────────────────────────────────

# Fires when estimated monthly AWS charges exceed $50.
# NOTE: Billing metrics are only published to us-east-1 regardless of deployment region.
# Billing alerts must be enabled in the AWS account: Billing Console → Billing Preferences → Receive Billing Alerts.
resource "aws_cloudwatch_metric_alarm" "billing_threshold" {
  alarm_name          = "${var.project_name}-billing-threshold"
  alarm_description   = "Estimated AWS charges have exceeded $50 this month"
  namespace           = "AWS/Billing"
  metric_name         = "EstimatedCharges"
  statistic           = "Maximum"
  period              = 86400
  evaluation_periods  = 1
  threshold           = 50
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  tags = {
    Name        = "${var.project_name}-billing-threshold"
    Environment = var.environment
  }
}
