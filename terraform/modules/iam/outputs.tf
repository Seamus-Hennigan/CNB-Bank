output "cloudtrail_role_arn" {
  value = aws_iam_role.cloudtrail.arn
}

output "cicd_role_arn" {
  value = aws_iam_role.cicd.arn
}

output "monitoring_role_arn" {
  value = aws_iam_role.monitoring.arn
}