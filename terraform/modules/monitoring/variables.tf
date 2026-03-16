variable "project_name" {
    description = "Name of the project"
    type = string
}

variable "environment" {
    description = "Environment (dev, staging, prod)"
    type = string
}

variable "aws_region" {
    description = "AWS region"
    type = string
}

variable "alb_arn" {
    description = "ALB ARN for CloudWatch metrics"
    type = string
}

variable "alert_email" {
    description = "Email address for CloudWatch alerts"
    type = string
}

variable "ecs_task_execution_role_arn" {
    description = "ECS task execution role ARN"
    type = string
}