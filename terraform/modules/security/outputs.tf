output "alb_sg_id" {
    value = aws_security_group.alb.id
}

output "banking_sg_id" {
    value = aws_security_group.banking.id
}

output "trading_sg_id" {
    value = aws_security_group.trading.id
}

output "rds_banking_sg_id" {
    value = aws_security_group.rds_banking.id
}

output "rds_trading_sg_id" {
    value = aws_security_group.rds_trading.id
}