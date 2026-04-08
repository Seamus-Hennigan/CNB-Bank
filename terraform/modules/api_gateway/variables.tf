variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "user_pool_arn" {
  description = "Cognito user pool ARN for authorizer"
  type        = string
}

variable "waf_arn" {
  description = "WAF web ACL ARN"
  type        = string
}

variable "cloudflare_tunnel_url" {
  description = "Cloudflare Tunnel URL for backend services"
  type        = string
}

# Custom domain for the API Gateway — used to expose the API at api.cnb-bank.org.
variable "custom_domain_name" {
  description = "Custom domain name for the API Gateway (e.g. api.cnb-bank.org)"
  type        = string
}

# ACM certificate ARN for the Cloudflare Origin CA certificate imported into ACM.
# This certificate authenticates the connection from Cloudflare to API Gateway.
variable "cloudflare_acm_certificate_arn" {
  description = "ACM certificate ARN for the imported Cloudflare Origin CA certificate"
  type        = string
}
