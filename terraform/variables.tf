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

# ── Cloudflare ────────────────────────────────────────────────────────────────

# Cloudflare API token — used by the Cloudflare provider to manage DNS and tunnels.
# Create at dash.cloudflare.com → My Profile → API Tokens.
# Required permissions: Zone:DNS:Edit, Account:Cloudflare Tunnel:Edit.
# Set as a sensitive workspace variable in Terraform Cloud — never commit it.
variable "cloudflare_api_token" {
  description = "Cloudflare API token for managing DNS records and tunnels"
  type        = string
  sensitive   = true
}

# Cloudflare Account ID — visible in the Cloudflare dashboard URL and right sidebar.
variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  default     = "df3a1bebb154776d069146481498a39e"
}

# The root domain registered in Cloudflare — used for DNS records and zone lookup.
variable "domain" {
  description = "Root domain managed in Cloudflare (e.g. cnb-bank.org)"
  type        = string
  default     = "cnb-bank.org"
}

# Base64-encoded 32-byte random secret used to authenticate the cloudflared daemon.
# Generate with: openssl rand -base64 32
# Set as a sensitive workspace variable in Terraform Cloud — never commit it.
variable "tunnel_secret" {
  description = "Base64-encoded 32-byte secret for Cloudflare Tunnel authentication"
  type        = string
  sensitive   = true
}

# URL cloudflared uses to forward traffic to Traefik on the Pi.
# If cloudflared runs as a pod inside the k3s cluster, use the Traefik ClusterIP DNS name.
# If cloudflared runs outside the cluster, use the Pi node IP + Traefik NodePort.
variable "traefik_service_url" {
  description = "Internal URL cloudflared uses to reach Traefik on the Pi"
  type        = string
  default     = "http://traefik.kube-system.svc.cluster.local:80"
}

# Custom domain for the API Gateway — exposed as api.cnb-bank.org via a Cloudflare DNS CNAME.
variable "custom_domain_name" {
  description = "Custom domain name for the API Gateway (e.g. api.cnb-bank.org)"
  type        = string
  default     = "api.cnb-bank.org"
}

# ARN of the ACM certificate holding the Cloudflare Origin CA certificate.
# This certificate authenticates the TLS connection from Cloudflare's edge to API Gateway.
# Import the Origin CA cert into ACM first, then provide the resulting ARN here.
variable "cloudflare_acm_certificate_arn" {
  description = "ACM certificate ARN for the imported Cloudflare Origin CA certificate"
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
