output "waf_arn" {
    value = aws_wafv2_web_acl.main.arn
}

output "waf_id" {
    value = aws_wafv2_web_acl.main.id
}

output "guardduty_detector_id" {
    value = aws_guardduty_detector.main.id
}

output "cloudtrail_arn" {
    value = aws_cloudtrail.main.arn
}