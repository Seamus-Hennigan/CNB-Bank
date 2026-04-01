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
