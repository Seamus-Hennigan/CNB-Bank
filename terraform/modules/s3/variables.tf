variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID — used to scope KMS key and bucket policies"
  type        = string
}
