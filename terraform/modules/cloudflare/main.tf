# Child modules must declare the source for any non-HashiCorp provider they use,
# otherwise Terraform defaults to registry.terraform.io/hashicorp/<name>.
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Look up the Cloudflare zone ID for cnb-bank.org.
# The zone must already exist in the Cloudflare account (it is created when a domain
# is added to Cloudflare — not a Terraform-managed resource).
data "cloudflare_zone" "main" {
  name = var.domain
}

# Create the Named Tunnel in the Cloudflare account.
# A Named Tunnel creates a secure outbound-only connection from the Pi to Cloudflare's
# edge — no inbound firewall ports need to be opened.
resource "cloudflare_zero_trust_tunnel_cloudflared" "main" {
  account_id = var.cloudflare_account_id
  name       = "${var.project_name}-${var.environment}-tunnel"
  secret     = var.tunnel_secret
}

# Configure the tunnel's ingress rules.
# All traffic arriving at services.cnb-bank.org is forwarded to Traefik on the Pi.
# Traefik then routes requests to the correct service (banking on 8080, trading on 8081)
# based on path rules configured in its own IngressRoute resources.
# The catch-all rule at the end is required by Cloudflare — it handles any hostname
# not explicitly matched by an ingress rule.
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "main" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main.id

  config {
    # Route all traffic for services.cnb-bank.org to Traefik on the Pi.
    ingress_rule {
      hostname = "services.${var.domain}"
      service  = var.traefik_service_url
    }

    # Required catch-all rule — returns 404 for any unmatched hostname.
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# DNS CNAME record pointing services.cnb-bank.org to the tunnel.
# The value is the tunnel's auto-assigned cfargotunnel.com hostname.
# proxied = true routes traffic through Cloudflare's edge (DDoS protection, etc.).
resource "cloudflare_record" "tunnel" {
  zone_id = data.cloudflare_zone.main.zone_id
  name    = "services"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.main.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true

  comment = "Cloudflare Tunnel entry point — routes API traffic to Traefik on the Pi"
}

# DNS CNAME record pointing app.cnb-bank.org to the CloudFront distribution.
# proxied = true means Cloudflare sits in front of CloudFront, providing an additional
# caching and security layer. Note: Cloudflare and CloudFront caching may interact —
# consider setting Cloudflare's cache to "bypass" for this record if caching issues arise.
resource "cloudflare_record" "frontend" {
  zone_id = data.cloudflare_zone.main.zone_id
  name    = "app"
  content = var.cloudfront_domain
  type    = "CNAME"
  proxied = true

  comment = "React frontend — CNAME to CloudFront distribution"
}

# DNS CNAME record for the apex domain (cnb-bank.org) pointing to app.cnb-bank.org.
# Cloudflare supports CNAME flattening at the zone apex, resolving the CNAME to an
# A record automatically so the root domain works without breaking RFC compliance.
resource "cloudflare_record" "root_redirect" {
  zone_id = data.cloudflare_zone.main.zone_id
  name    = "@"
  content = "app.${var.domain}"
  type    = "CNAME"
  proxied = true

  comment = "Apex domain — flattened CNAME to app.cnb-bank.org"
}

# DNS CNAME record pointing api.cnb-bank.org to the API Gateway regional endpoint.
# proxied = false is required — API Gateway validates the certificate on the TLS connection,
# which breaks if Cloudflare terminates TLS before it reaches the regional endpoint.
resource "cloudflare_record" "api" {
  zone_id = data.cloudflare_zone.main.zone_id
  name    = "api"
  content = var.api_gateway_regional_domain
  type    = "CNAME"
  proxied = false

  comment = "API Gateway custom domain — CNAME to regional endpoint"
}
