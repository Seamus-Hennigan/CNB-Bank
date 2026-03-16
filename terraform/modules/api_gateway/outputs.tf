output "api_gateway_id" {
  value = aws_api_gateway_rest_api.main.id
}

output "api_gateway_url" {
  value = aws_api_gateway_stage.main.invoke_url
}

output "api_gateway_arn" {
  value = aws_api_gateway_stage.main.arn
}