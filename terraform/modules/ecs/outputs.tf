output "cluster_id" {
  value = aws_ecs_cluster.cluster.id
}

output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "banking_service_name" {
  value = aws_ecs_service.banking.name
}

output "trading_service_name" {
  value = aws_ecs_service.trading.name
}

output "banking_task_definition_arn" {
  value = aws_ecs_task_definition.banking.arn
}

output "trading_task_definition_arn" {
  value = aws_ecs_task_definition.trading.arn
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}