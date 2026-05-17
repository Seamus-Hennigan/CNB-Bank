# Alarm ARNs — useful for wiring SNS notifications if alerting is added later.

output "api_5xx_alarm_arn" {
  description = "ARN of the API Gateway 5XX error alarm"
  value       = aws_cloudwatch_metric_alarm.api_5xx_errors.arn
}

output "api_latency_alarm_arn" {
  description = "ARN of the API Gateway p99 latency alarm"
  value       = aws_cloudwatch_metric_alarm.api_latency_p99.arn
}

output "waf_blocked_alarm_arn" {
  description = "ARN of the WAF blocked requests alarm"
  value       = aws_cloudwatch_metric_alarm.waf_blocked_requests.arn
}

output "s3_4xx_alarm_arn" {
  description = "ARN of the S3 4XX errors alarm"
  value       = aws_cloudwatch_metric_alarm.s3_4xx_errors.arn
}

output "billing_alarm_arn" {
  description = "ARN of the billing threshold alarm"
  value       = aws_cloudwatch_metric_alarm.billing_threshold.arn
}
