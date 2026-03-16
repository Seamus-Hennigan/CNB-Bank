output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.main.arn
}

output "frontend_client_id" {
  value = aws_cognito_user_pool_client.frontend.id
}

output "user_pool_domain" {
  value = aws_cognito_user_pool_domain.main.domain
}