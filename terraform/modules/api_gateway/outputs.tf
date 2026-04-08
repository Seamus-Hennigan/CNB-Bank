output "api_gateway_id" {
  value = aws_api_gateway_rest_api.main.id
}

output "api_gateway_url" {
  value = aws_api_gateway_stage.main.invoke_url
}

output "api_gateway_arn" {
  value = aws_api_gateway_stage.main.arn
}

# Regional domain name for the custom domain — passed to the cloudflare module
# so it can create the api.cnb-bank.org CNAME record pointing here.
output "regional_domain_name" {
  description = "API Gateway regional domain name for the custom domain CNAME"
  value       = aws_api_gateway_domain_name.main.regional_domain_name
}