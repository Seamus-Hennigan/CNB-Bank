variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS services"
  type        = list(string)
}

variable "banking_sg_id" {
  description = "Security group ID for banking service"
  type        = string
}

variable "trading_sg_id" {
  description = "Security group ID for trading service"
  type        = string
}

variable "banking_target_group_arn" {
  description = "Target group ARN for banking service"
  type        = string
}

variable "trading_target_group_arn" {
  description = "Target group ARN for trading service"
  type        = string
}

variable "banking_image" {
  description = "Docker image for banking service"
  type        = string
  default     = "nginx:latest"
}

variable "trading_image" {
  description = "Docker image for trading service"
  type        = string
  default     = "nginx:latest"
}

variable "banking_cpu" {
  description = "CPU units for banking task"
  type        = number
  default     = 256
}

variable "banking_memory" {
  description = "Memory for banking task in MB"
  type        = number
  default     = 512
}

variable "trading_cpu" {
  description = "CPU units for trading task"
  type        = number
  default     = 256
}

variable "trading_memory" {
  description = "Memory for trading task in MB"
  type        = number
  default     = 512
}

variable "banking_desired_count" {
  description = "Desired number of banking containers"
  type        = number
  default     = 1
}

variable "trading_desired_count" {
  description = "Desired number of trading containers"
  type        = number
  default     = 1
}

variable "banking_max_count" {
  description = "Maximum number of banking containers"
  type        = number
  default     = 4
}

variable "trading_max_count" {
  description = "Maximum number of trading containers"
  type        = number
  default     = 4
}