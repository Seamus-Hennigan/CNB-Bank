# ── AWS ───────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cnb"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "cloudflare_tunnel_url" {
  description = "Cloudflare Tunnel URL for API Gateway backend — points to services on the Pi"
  type        = string
}

# ── Kubernetes (Raspberry Pi k3s cluster) ─────────────────────────────────────

# Path on the Terraform Cloud agent machine to the kubeconfig for the Pi cluster.
variable "kubernetes_config_path" {
  description = "Path to the kubeconfig file for the k3s cluster on the Raspberry Pi"
  type        = string
  default     = "~/.kube/config"
}

# Kubeconfig context to use when multiple clusters are present in the file.
variable "kubernetes_context" {
  description = "Kubeconfig context name for the Raspberry Pi k3s cluster"
  type        = string
  default     = "default"
}

# ECR image tag for the banking service — typically a git SHA or 'latest'.
variable "banking_image_tag" {
  description = "Docker image tag for the banking service, pushed to ECR"
  type        = string
  default     = "latest"
}

# ECR image tag for the trading service.
variable "trading_image_tag" {
  description = "Docker image tag for the trading service, pushed to ECR"
  type        = string
  default     = "latest"
}

# Pod replica count for the banking Deployment.
variable "banking_replicas" {
  description = "Number of pod replicas for the banking Kubernetes Deployment"
  type        = number
  default     = 1
}

# Pod replica count for the trading Deployment.
variable "trading_replicas" {
  description = "Number of pod replicas for the trading Kubernetes Deployment"
  type        = number
  default     = 1
}

# PostgreSQL password for the banking database — stored as a Kubernetes Secret.
# Set this as a sensitive workspace variable in Terraform Cloud; never commit it.
variable "banking_db_password" {
  description = "Password for the banking PostgreSQL database running on Kubernetes"
  type        = string
  sensitive   = true
}

# PostgreSQL password for the trading database — stored as a Kubernetes Secret.
variable "trading_db_password" {
  description = "Password for the trading PostgreSQL database running on Kubernetes"
  type        = string
  sensitive   = true
}
