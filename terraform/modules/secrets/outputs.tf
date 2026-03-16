output "banking_db_secret_arn" {
  value = aws_secretsmanager_secret.banking_db.arn
}

output "trading_db_secret_arn" {
  value = aws_secretsmanager_secret.trading_db.arn
}

output "stock_api_secret_arn" {
  value = aws_secretsmanager_secret.stock_api.arn
}