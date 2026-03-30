module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment = var.environment
}

module "cognito" {
  source = "./modules/cognito"

  project_name = var.project_name
  environment = var.environment
  callback_urls = ["http://localhost:3000/callback"]
  logout_urls = ["http://localhost:3000/logout"]
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment = var.environment
  aws_account_id = var.aws_account_id
  github_repo = var.github_repo
}

module "waf" {
  source = "./modules/waf"

  project_name = var.project_name
  environment = var.environment
  aws_account_id = var.aws_account_id
}

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name = var.project_name
  environment = var.environment
  user_pool_arn = module.cognito.user_pool_arn
  cloudflare_tunnel_url = var.cloudflare_tunnel_url
  waf_arn = module.waf.waf_arn
}




