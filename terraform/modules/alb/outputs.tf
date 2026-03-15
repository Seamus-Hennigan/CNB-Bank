output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "banking_target_group_arn" {
  value = aws_lb_target_group.banking.arn
}

output "trading_target_group_arn" {
  value = aws_lb_target_group.trading.arn
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}