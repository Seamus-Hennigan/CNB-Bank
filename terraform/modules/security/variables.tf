variable "project_name" {
  description = "Name of the project"
  type = string
}

variable "environment" {
  description = "Enviorment (dev, staging, prod)"
  type = string
}

variable "vpc_id" {
    description = "VPC ID to create security group in"
    type = string
}