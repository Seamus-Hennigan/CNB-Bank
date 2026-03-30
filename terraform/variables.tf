variable "aws_region" {
  description = "AWS region to deploy resources"
  type = string
  default = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type = string
  default = "cnb"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type = string
  default = "dev"
}



variable "aws_account_id" {
  description = "AWS account ID"
  type = string
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo"
  type = string
}

variable "cloudflare_tunnel_url" {
  description = "Cloudflare Tunnel URL for API Gateway backend"
  type = string
}




