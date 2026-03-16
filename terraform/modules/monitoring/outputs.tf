output "sns_topic_arn" {
    value = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
    value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "prometheus_task_definition_arn" {
    value = aws_ecs_task_definition.prometheus.arn
}

output "grafana_task_definition_arn" {
    value = aws_ecs_task_definition.grafana.arn
}