variable "project_Name" {
    description = "Name of the project"
    type = string
}

variable "Environment" {
    description = "Enviorment (dev, staging, prod)"
    type = string
}

variable "private_subnet_ids" {
    description = "Private subnet IDs for RDS"
    type = list(string)
}

variable "rds_banking_sg_id" {
  description = "Security group ID for banking RDS"
  type = string
}

variable "rds_trading_sg_id" {
    description = "Security group ID for trading RDS"
    type = string
}

variable "db_instance_class" {
    description = "RDS insance class"
    type = string
    default = "db.t3.micro"
}

variable "allocated_storage" {
    description = "Allocated storage in GB"
    type = number
    default = 20
}

variable "banking_db_userName" {
    description = "Master userName for banking database"
    type = string
    sensitive = true
}

variable "banking_db_password" {
    description = "Master password for banking database"
    type = string
    sensitive = true
}

variable "trading_db_userName" {
    description = "Master userName for trading database"
    type = string
    sensitive = true
}

variable "trading_db_password" {
    description = "Master password for trading database"
    type = string
    sensitive = true
}



