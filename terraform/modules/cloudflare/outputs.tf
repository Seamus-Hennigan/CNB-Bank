# The hostname used as the Cloudflare Tunnel entry point.
# This replaces the old cloudflare_tunnel_url variable and is passed to the
# API Gateway module so it can construct its backend integration URIs.
output "tunnel_url" {
  description = "Hostname of the Cloudflare Tunnel entry point (services.<domain>)"
  value       = "services.${var.domain}"
}

# The cloudflared run token — run this on the Pi to connect the tunnel:
#   cloudflared tunnel run --token <token>
# Retrieve with: terraform output -raw cloudflare_tunnel_token
output "tunnel_token" {
  description = "cloudflared authentication token — configure on the Pi to connect the tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.tunnel_token
  sensitive   = true
}

# The Cloudflare Tunnel UUID — useful for debugging and Cloudflare dashboard navigation.
output "tunnel_id" {
  description = "Cloudflare Tunnel UUID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main.id
}

# The Cloudflare zone ID for cnb-bank.org — useful if other modules need to add DNS records.
output "zone_id" {
  description = "Cloudflare zone ID for the domain"
  value       = data.cloudflare_zone.main.zone_id
}
