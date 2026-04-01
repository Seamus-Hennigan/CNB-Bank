output "cloudtrail_role_arn" {
  description = "ARN of the IAM role used by CloudTrail to write to CloudWatch Logs"
  value       = aws_iam_role.cloudtrail.arn
}

output "monitoring_role_arn" {
  description = "ARN of the IAM role used by the monitoring agent"
  value       = aws_iam_role.monitoring.arn
}

# IAM access key ID for the Jenkins CI/CD user — configure this in Jenkins credentials.
output "jenkins_access_key_id" {
  description = "AWS access key ID for the Jenkins CI/CD IAM user"
  value       = aws_iam_access_key.jenkins.id
}

# The secret access key is sensitive — retrieve it once and store it in Jenkins credentials.
output "jenkins_secret_access_key" {
  description = "AWS secret access key for the Jenkins CI/CD IAM user (sensitive)"
  value       = aws_iam_access_key.jenkins.secret
  sensitive   = true
}

output "jenkins_iam_user_name" {
  description = "IAM username for the Jenkins CI/CD user"
  value       = aws_iam_user.jenkins.name
}
