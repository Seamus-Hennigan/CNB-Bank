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

variable "banking_db_username" {
  description = "Master userName for banking database"
  type = string
  sensitive = true
}

variable "banking_db_password" {
  description = "Master password for banking database"
  type = string
  sensitive = true
}

variable "trading_db_username" {
  description = "Master userName for trading database"
  type = string
  sensitive = true
}

variable "trading_db_password" {
  description = "Master password for trading database"
  type = string
  sensitive = true
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type = string
  
}