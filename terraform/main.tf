module "vpc" {
    source = "./modules/vpc"

    project_name = var.project_name
    Environment = var.environment
    vpc_cidr = "10.0.0.0/16"
    public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
    availability_zones = ["us-east-1a", "us-east-1b"]
}

module "security" {
    source = "./modules/security"

    project_name = var.project_name
    Environment = var.environment
    vpc_id = module.vpc.vpc_id
}

module "rds" {
  source = "./modules/rds"

  project_name = var.project_name
  Environment = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_banking_sg_id = module.security.rds_banking_sg_id
  rds_trading_sg_id = module.security.rds_trading_sg_id

  banking_db_username = var.banking_db_username
  banking_db_password = var.banking_db_password
  trading_db_username = var.trading_db_username
  trading_db_password = var.trading_db_password
}

module "alb" {
    source = "./modules/alb"

    project_name = var.project_name
    environment = var.environment
    vpc_id = module.vpc.vpc_id
    public_subnet_ids = module.vpc.public_subnet_ids
    alb_sg_id = module.security.alb_sg_id
    certificate_arn = var.certificate_arn
}

module "ecs" {
  source = "./modules/ecs"

  project_name = var.project_name
  environment = var.environment
  aws_region = var.aws_region
  private_subnet_ids = module.vpc.private_subnet_ids
  banking_sg_id = module.security.banking_sg_id
  trading_sg_id = module.security.trading_sg_id
  banking_target_group_arn = module.alb.banking_target_group_arn
  trading_target_group_arn = module.alb.trading_target_group_arn
}

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

module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment

  banking_db_endpoint = module.rds.banking_db_endpoint
  banking_db_name     = module.rds.banking_db_name
  banking_db_username = var.banking_db_username
  banking_db_password = var.banking_db_password

  trading_db_endpoint = module.rds.trading_db_endpoint
  trading_db_name     = module.rds.trading_db_name
  trading_db_username = var.trading_db_username
  trading_db_password = var.trading_db_password

  stock_api_key = var.stock_api_key

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
  alb_dns_name = module.alb.alb_dns_name
  waf_arn = module.waf.waf_arn
}