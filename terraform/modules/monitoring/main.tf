# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
    dashboard_name = "${var.project_name}-dashboard"

    dashboard_body = jsonencode({
        widgets = [
        {
            type = "metric"
            properties = {
            title = "ECS Banking Service CPU"
            period = 300
            stat  = "Average"
            metrics = [
                ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-banking-service"]
            ]
            }
        },
        {
            type = "metric"
            properties = {
            title = "ECS Trading Service CPU"
            period = 300
            stat = "Average"
            metrics = [
                ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-trading-service"]
            ]
            }
        },
        {
            type = "metric"
            properties = {
            title = "ALB Request Count"
            period = 300
            stat = "Sum"
            metrics = [
                ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn]
            ]
            }
        },
        {
            type = "metric"
            properties = {
            title = "RDS Banking CPU"
            period = 300
            stat = "Average"
            metrics = [
                ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.project_name}-banking-db"]
            ]
            }
        },
        {
            type = "metric"
            properties = {
            title = "RDS Trading CPU"
            period = 300
            stat = "Average"
            metrics = [
                ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.project_name}-trading-db"]
            ]
            }
        }
        ]
    })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "banking_cpu_high" {
    alarm_name = "${var.project_name}-banking-cpu-high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 2
    metric_name = "CPUUtilization"
    namespace = "AWS/ECS"
    period = 120
    statistic = "Average"
    threshold = 80
    alarm_description = "Banking service CPU above 80%"

    dimensions = {
        ServiceName = "${var.project_name}-banking-service"
    }

    tags = {
        Name = "${var.project_name}-banking-cpu-alarm"
        Environment = var.environment
    }
}

resource "aws_cloudwatch_metric_alarm" "trading_cpu_high" {
    alarm_name = "${var.project_name}-trading-cpu-high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name = "CPUUtilization"
    namespace  = "AWS/ECS"
    period = 120
    statistic = "Average"
    threshold = 80
    alarm_description   = "Trading service CPU above 80%"

    dimensions = {
        ServiceName = "${var.project_name}-trading-service"
    }

    tags = {
        Name = "${var.project_name}-trading-cpu-alarm"
        Environment = var.environment
    }
}

resource "aws_cloudwatch_metric_alarm" "banking_db_cpu_high" {
    alarm_name = "${var.project_name}-banking-db-cpu-high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 2
    metric_name = "CPUUtilization"
    namespace = "AWS/RDS"
    period = 120
    statistic = "Average"
    threshold = 80
    alarm_description = "Banking DB CPU above 80%"

    dimensions = {
        DBInstanceIdentifier = "${var.project_name}-banking-db"
    }

    tags = {
        Name = "${var.project_name}-banking-db-alarm"
        Environment = var.environment
    }
}

resource "aws_cloudwatch_metric_alarm" "trading_db_cpu_high" {
    alarm_name = "${var.project_name}-trading-db-cpu-high"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 2
    metric_name = "CPUUtilization"
    namespace = "AWS/RDS"
    period = 120
    statistic = "Average"
    threshold = 80
    alarm_description = "Trading DB CPU above 80%"

    dimensions = {
        DBInstanceIdentifier = "${var.project_name}-trading-db"
    }

    tags = {
        Name = "${var.project_name}-trading-db-alarm"
        Environment = var.environment
    }
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
    name = "${var.project_name}-alerts"

    tags = {
        Name = "${var.project_name}-alerts"
        Environment = var.environment
    }
}

resource "aws_sns_topic_subscription" "alerts_email" {
    topic_arn = aws_sns_topic.alerts.arn
    protocol = "email"
    endpoint = var.alert_email
}

# Prometheus ECS Task Definition
resource "aws_ecs_task_definition" "prometheus" {
    family = "${var.project_name}-prometheus"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = 256
    memory = 512
    execution_role_arn = var.ecs_task_execution_role_arn

    container_definitions = jsonencode([
        {
        name = "prometheus"
        image = "prom/prometheus:latest"
        essential = true

        portMappings = [
            {
            containerPort = 9090
            protocol = "tcp"
            }
        ]

        logConfiguration = {
            logDriver = "awslogs"
            options = {
            "awslogs-group" = "/ecs/${var.project_name}/prometheus"
            "awslogs-region" = var.aws_region
            "awslogs-stream-prefix" = "prometheus"
            }
        }
        }
    ])

    tags = {
        Name = "${var.project_name}-prometheus-task"
        Environment = var.environment
    }
}

# Grafana ECS Task Definition
resource "aws_ecs_task_definition" "grafana" {
    family = "${var.project_name}-grafana"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = 256
    memory = 512
    execution_role_arn = var.ecs_task_execution_role_arn

    container_definitions = jsonencode([
        {
        name = "grafana"
        image = "grafana/grafana:latest"
        essential = true

        portMappings = [
            {
            containerPort = 3000
            protocol = "tcp"
            }
        ]

        logConfiguration = {
            logDriver = "awslogs"
            options = {
            "awslogs-group" = "/ecs/${var.project_name}/grafana"
            "awslogs-region" = var.aws_region
            "awslogs-stream-prefix" = "grafana"
            }
        }
        }
    ])

    tags = {
        Name = "${var.project_name}-grafana-task"
        Environment = var.environment
    }
}

# CloudWatch Log Groups for Prometheus and Grafana
resource "aws_cloudwatch_log_group" "prometheus" {
    name = "/ecs/${var.project_name}/prometheus"
    retention_in_days = 30

    tags = {
        Name = "${var.project_name}-prometheus-logs"
        Environment = var.environment
    }
}

resource "aws_cloudwatch_log_group" "grafana" {
    name = "/ecs/${var.project_name}/grafana"
    retention_in_days = 30

    tags = {
        Name = "${var.project_name}-grafana-logs"
        Environment = var.environment
    }
}