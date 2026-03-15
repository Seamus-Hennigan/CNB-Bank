variable "project_Name" {
  description = "Name of the project"
  type = string
}

variable "Environment" {
  description = "Enviorment (dev, staging, prod)"
  type = string
}

variable "vpc_id" {
    description = "VPC ID to create security group in"
    type = string
}