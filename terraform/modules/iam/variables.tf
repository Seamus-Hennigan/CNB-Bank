variable "project_name" {
  description = "Name of the project"
  type = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type = string
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo"
  type = string
}