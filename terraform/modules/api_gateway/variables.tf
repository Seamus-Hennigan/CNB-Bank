variable "project_name" {
  description = "Name of the project"
  type = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type = string
}

variable "user_pool_arn" {
  description = "Cognito user pool ARN for authorizer"
  type = string
}

variable "waf_arn" {
  description = "WAF web ACL ARN"
  type = string
}

variable "cloudflare_tunnel_url" {
  description = "Cloudflare Tunnel URL for backend services"
  type = string
}