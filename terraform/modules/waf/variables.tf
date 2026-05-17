# Project name prefix applied to all WAF resource names and tags.
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# Deployment environment label applied to resource tags.
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# AWS account ID — required to construct the CloudTrail S3 bucket policy resource ARN.
variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

# ARN of the IAM role CloudTrail assumes to deliver events to CloudWatch Logs.
# Created in the iam module and passed in from the root module.
variable "cloudtrail_cw_logs_role_arn" {
  description = "IAM role ARN CloudTrail uses to write to its CloudWatch log group"
  type        = string
}
