output "banking_db_endpoint" {
    value = aws_db_instance.banking.endpoint
}

output "trading_db_endpoint" {
    value = aws_db_instance.trading.endpoint
}

output "banking_db_Name" {
  value = aws_db_instance.banking.db_Name
}

output "trading_db_Name" {
    value = aws_db_instance.trading.db_Name
}