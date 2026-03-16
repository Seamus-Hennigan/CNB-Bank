variable "project_name" {
    description = "Name of the project"
    type = string
}

variable "environment" {
    description = "Environment (dev, staging, prod)"
    type = string
}

variable "vpc_id" {
    description = "VPC ID"
    type = string
}

variable "public_subnet_ids" {
    description = "Public subnet ID's for ALB"
    type = list(string)
}

variable "alb_sg_id" {
    description = "Security group ID for ALB"
    type = string
}

variable "certificate_arn" {
    description = "ACM certificate for ARN for HTTPS"
    type = string
}