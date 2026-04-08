# Project name prefix — used to name the Cloudflare Tunnel.
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# Deployment environment label applied to resource tags and tunnel name.
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# Cloudflare Account ID — required by tunnel and DNS resources.
variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

# The root domain purchased in Cloudflare — used to look up the zone and build record names.
variable "domain" {
  description = "Root domain managed in Cloudflare (e.g. cnb-bank.org)"
  type        = string
}

# Base64-encoded 32-byte random secret used to authenticate the tunnel.
# Generate with: openssl rand -base64 32
# Store as a sensitive workspace variable in Terraform Cloud — never commit it.
variable "tunnel_secret" {
  description = "Base64-encoded 32-byte secret for Cloudflare Tunnel authentication"
  type        = string
  sensitive   = true
}

# The URL cloudflared uses to forward traffic to Traefik on the Pi cluster.
# If cloudflared runs as a pod inside the cluster, use the Traefik ClusterIP DNS name.
# If cloudflared runs outside the cluster, use the node IP + Traefik's NodePort.
variable "traefik_service_url" {
  description = "Internal URL cloudflared uses to reach Traefik on the Pi (e.g. http://traefik.kube-system.svc.cluster.local:80)"
  type        = string
  default     = "http://traefik.kube-system.svc.cluster.local:80"
}

# CloudFront domain name output from the s3 module — used for the frontend DNS CNAME.
variable "cloudfront_domain" {
  description = "CloudFront distribution domain name for the React frontend"
  type        = string
}

# Regional domain name output from the api_gateway module — used for the api.cnb-bank.org DNS CNAME.
# API Gateway requires a direct (non-proxied) CNAME to its regional endpoint.
variable "api_gateway_regional_domain" {
  description = "API Gateway regional domain name for the api.cnb-bank.org CNAME record"
  type        = string
}
