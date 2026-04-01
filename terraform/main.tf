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
# Requests are forwarded to the Pi cluster via the Cloudflare Tunnel.
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name          = var.project_name
  environment           = var.environment
  user_pool_arn         = module.cognito.user_pool_arn
  cloudflare_tunnel_url = var.cloudflare_tunnel_url
  waf_arn               = module.waf.waf_arn
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
