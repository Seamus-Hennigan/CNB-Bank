# Project name prefix used to namespace all Kubernetes resource names and labels.
variable "project_name" {
  description = "Project name prefix, used to name Kubernetes resources"
  type        = string
}

# Deployment environment label applied to Kubernetes labels and annotations.
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# AWS account ID — used to construct the ECR image repository URI.
variable "aws_account_id" {
  description = "AWS account ID, used to build the ECR repository URI"
  type        = string
}

# AWS region where the ECR repositories are hosted.
variable "aws_region" {
  description = "AWS region where ECR repositories are hosted"
  type        = string
}

# Docker image tag to pull from ECR for the banking service (e.g. git SHA or 'latest').
variable "banking_image_tag" {
  description = "Docker image tag for the banking service"
  type        = string
  default     = "latest"
}

# Docker image tag to pull from ECR for the trading service.
variable "trading_image_tag" {
  description = "Docker image tag for the trading service"
  type        = string
  default     = "latest"
}

# Number of pod replicas for the banking Deployment.
variable "banking_replicas" {
  description = "Number of pod replicas for the banking Deployment"
  type        = number
  default     = 1
}

# Number of pod replicas for the trading Deployment.
variable "trading_replicas" {
  description = "Number of pod replicas for the trading Deployment"
  type        = number
  default     = 1
}

# PostgreSQL password for the banking database — stored as a Kubernetes Secret.
variable "banking_db_password" {
  description = "Password for the banking PostgreSQL StatefulSet"
  type        = string
  sensitive   = true
}

# PostgreSQL password for the trading database — stored as a Kubernetes Secret.
variable "trading_db_password" {
  description = "Password for the trading PostgreSQL StatefulSet"
  type        = string
  sensitive   = true
}
