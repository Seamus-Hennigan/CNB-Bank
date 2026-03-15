module "vpc" {
    source = "./modules/vpc"

    project_name = var.project_name
    enviornment = var.environment
    vpc_cidr = "10.0.0.0/16"
    public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
    availability_zones = ["us-east-1a", "us-east-1b"]
}

module "security" {
    source = "./modules/security"

    project_name = var.project_name
    environment = var.environment
    vpc_id = module.vpc.vpc_id
}