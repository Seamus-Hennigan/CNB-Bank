variable "project_name" {
  description = "Name of the project"
  type = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type = string
}

variable "banking_db_endpoint" {
  description = "Banking RDS endpoint"
  type = string
}

variable "banking_db_name" {
  description = "Banking database name"
  type = string
}

variable "banking_db_username" {
  description = "Banking database username"
  type = string
  sensitive = true
}

variable "banking_db_password" {
  description = "Banking database password"
  type = string
  sensitive = true
}

variable "trading_db_endpoint" {
  description = "Trading RDS endpoint"
  type = string
}

variable "trading_db_name" {
  description = "Trading database name"
  type = string
}

variable "trading_db_username" {
  description = "Trading database username"
  type = string
  sensitive = true
}

variable "trading_db_password" {
  description = "Trading database password"
  type = string
  sensitive = true
}

variable "stock_api_key" {
  description = "Stock market API key"
  type = string
  sensitive = true
}