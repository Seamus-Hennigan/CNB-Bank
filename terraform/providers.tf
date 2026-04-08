terraform {
  # Terraform Cloud stores remote state and runs plans/applies via an agent pool.
  # The agent must be registered to this organization and have kubeconfig access to the Pi.
  cloud {
    organization = "CNB-Bank"

    workspaces {
      name = "CNB-Bank"
    }
  }

  required_providers {
    # AWS provider — used for all AWS resources (S3, CloudFront, Cognito, API Gateway, WAF, IAM).
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Kubernetes provider — used to manage workloads on the self-hosted Raspberry Pi k3s cluster.
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    # Cloudflare provider — manages the tunnel, DNS records, and zone for cnb-bank.org.
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0"
}

# AWS provider — all AWS resources are deployed into the region specified by var.aws_region.
provider "aws" {
  region = var.aws_region
}

# Kubernetes provider — connects to the k3s cluster on the Raspberry Pi using a local
# kubeconfig file. The Terraform Cloud agent resolves the path and context locally.
provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_context
}

# Cloudflare provider — authenticates using an API token stored as a sensitive
# workspace variable in Terraform Cloud. Never commit the token to source control.
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
