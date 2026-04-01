output "waf_arn" {
  description = "ARN of the WAF Web ACL, passed to the API Gateway association"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}
