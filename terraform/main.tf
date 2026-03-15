module "vpc" {
    source = "./modules/vpc"

    project_Name = var.project_Name
    Environment = var.Environment
    vpc_cidr = "10.0.0.0/16"
    public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
    availability_zones = ["us-east-1a", "us-east-1b"]
}

module "security" {
    source = "./modules/security"

    project_Name = var.project_Name
    Environment = var.Environment
    vpc_id = module.vpc.vpc_id
}

module "rds" {
    source = "./modules/rds"

    project_Name       = var.project_Name
    Environment        = var.Environment
    private_subnet_ids = module.vpc.private_subnet_ids
    rds_banking_sg_id  = module.security.rds_banking_sg_id
    rds_trading_sg_id  = module.security.rds_trading_sg_id

    banking_db_userName = var.banking_db_userName
    banking_db_password = var.banking_db_password
    trading_db_userName = var.trading_db_userName
    trading_db_password = var.trading_db_password
}