output "banking_db_endpoint" {
    value = aws_db_instance.banking.endpoint
}

output "trading_db_endpoint" {
    value = aws_db_instance.trading.endpoint
}

output "banking_db_name" {
  value = aws_db_instance.banking.db_name
}

output "trading_db_name" {
    value = aws_db_instance.trading.db_name
}