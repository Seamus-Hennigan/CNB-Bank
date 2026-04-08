# The tunnel URL is pure string interpolation — no resource dependency — so it can be
# used as a local to break the circular dependency between the cloudflare and
# api_gateway modules (cloudflare needs api_gateway's regional domain; api_gateway
# needs the tunnel URL, which is just "services.<domain>").
locals {
  tunnel_url = "services.${var.domain}"
}

# S3 bucket for frontend static files and CloudFront distribution serving the React SPA.
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# Cognito User Pool, app client, hosted-UI domain, and user groups for authentication.
module "cognito" {
  source = "./modules/cognito"

  project_name  = var.project_name
  environment   = var.environment
  callback_urls = ["http://localhost:3000/callback"]
  logout_urls   = ["http://localhost:3000/logout"]
}

# IAM roles for CloudTrail, GuardDuty, and monitoring.
# Jenkins CI/CD IAM user and access key are also provisioned here.
module "iam" {
  source = "./modules/iam"

  project_name   = var.project_name
  environment    = var.environment
  aws_account_id = var.aws_account_id
}

# WAF Web ACL, GuardDuty detector, CloudTrail trail, and CloudTrail S3 log bucket.
module "waf" {
  source = "./modules/waf"

  project_name   = var.project_name
  environment    = var.environment
  aws_account_id = var.aws_account_id
}

# API Gateway REST API with Cognito authorizer and proxy routes for banking and trading.
# Requests are forwarded to the Pi cluster via the Cloudflare Tunnel (services.cnb-bank.org).
# Uses local.tunnel_url instead of module.cloudflare.tunnel_url to avoid a circular
# dependency (cloudflare module needs this module's regional_domain_name output).
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name                   = var.project_name
  environment                    = var.environment
  user_pool_arn                  = module.cognito.user_pool_arn
  cloudflare_tunnel_url          = local.tunnel_url
  waf_arn                        = module.waf.waf_arn
  custom_domain_name             = var.custom_domain_name
  cloudflare_acm_certificate_arn = var.cloudflare_acm_certificate_arn
}

# Cloudflare Tunnel, DNS records, and zone configuration for cnb-bank.org.
# Creates the Named Tunnel, configures ingress routing to Traefik on the Pi,
# and sets up DNS CNAMEs for the frontend (app.cnb-bank.org), tunnel (services.cnb-bank.org),
# and API Gateway custom domain (api.cnb-bank.org).
module "cloudflare" {
  source = "./modules/cloudflare"

  project_name                = var.project_name
  environment                 = var.environment
  cloudflare_account_id       = var.cloudflare_account_id
  domain                      = var.domain
  tunnel_secret               = var.tunnel_secret
  traefik_service_url         = var.traefik_service_url
  cloudfront_domain           = module.s3.cloudfront_domain_name
  api_gateway_regional_domain = module.api_gateway.regional_domain_name
}

# Kubernetes workloads running on the self-hosted Raspberry Pi k3s cluster.
# Includes banking and trading Deployments, their PostgreSQL StatefulSets,
# PersistentVolumeClaims, ConfigMaps, Secrets, and ClusterIP Services.
module "kubernetes" {
  source = "./modules/kubernetes"

  project_name        = var.project_name
  environment         = var.environment
  aws_account_id      = var.aws_account_id
  aws_region          = var.aws_region
  banking_image_tag   = var.banking_image_tag
  trading_image_tag   = var.trading_image_tag
  banking_replicas    = var.banking_replicas
  trading_replicas    = var.trading_replicas
  banking_db_password = var.banking_db_password
  trading_db_password = var.trading_db_password
}
