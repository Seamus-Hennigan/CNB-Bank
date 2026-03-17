#ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-cluster"

    setting {
    name  = "containerInsights"
    value = "enabled"
  }

    tags = {
    Name = "${var.project_name}-cluster"
    Environment = var.environment
    }
}



#ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
    name = "${var.project_name}-ecs-task-execution-role"



    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ecs-tasks.amazonaws.com"
                }
            }
        ]
    })

    tags = {
        Name = "${var.project_name}-ecs-task-execution-role"
        Environment = var.environment
    }
}

resource  "aws_iam_role_policy_attachment" "ecs_task_execution" {
    role = aws_iam_role.ecs_task_execution.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#ECS Task Role (for app permissions)
resource "aws_iam_role" "ecs_task" {
    name = "${var.project_name}-ecs-task-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ecs-tasks.amazonaws.com"
                }
            }
        ]
    })

    tags = {
        Name = "${var.project_name}-ecs-task-role"
        Environment = var.environment
    }
}

#Allow ECS tasks to access Secrets Manager
resource "aws_iam_role_policy" "ecs_task_secrets" {
    name = "${var.project_name}-ecs-task-secrets-policy"
    role = aws_iam_role.ecs_task.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "secretsmanager:GetSecretValue"
                ]
                Resource = "*"
            }
        ]
    })
}


#CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "banking" {
    name = "/ecs/${var.project_name}/banking"
    retention_in_days = 30

    tags = {
        Name = "${var.project_name}-banking-log"
        Environment = var.environment
    }
}

resource  "aws_cloudwatch_log_group" "trading" {
    name = "/ecs/${var.project_name}/trading"
    retention_in_days = 30

    tags = {
        Name = "${var.project_name}-trading-log"
        Environment = var.environment
    }
}

# Banking Task Definition
resource "aws_ecs_task_definition" "banking" {
  family = "${var.project_name}-banking"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = var.banking_cpu
  memory = var.banking_memory
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name = "banking-api"
      image = var.banking_image
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = aws_cloudwatch_log_group.banking.name
          "awslogs-region" = var.aws_region
          "awslogs-stream-prefix" = "banking"
        }
      }

      environment = [
        {
          name = "ENVIRONMENT"
          value = var.environment
        }
      ]
    }
  ])

  tags = {
    Name = "${var.project_name}-banking-task"
    Environment = var.environment
  }
}


# Trading Task Definition
resource "aws_ecs_task_definition" "trading" {
    family = "${var.project_name}-trading"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = var.trading_cpu
    memory = var.trading_memory
    execution_role_arn = aws_iam_role.ecs_task_execution.arn
    task_role_arn = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name = "trading-api"
      image = var.trading_image
      essential = true

      portMappings = [
        {
          containerPort = 8081
          protocol = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = aws_cloudwatch_log_group.trading.name
          "awslogs-region" = var.aws_region
          "awslogs-stream-prefix" = "trading"
        }
      }

      environment = [
        {
          name = "ENVIRONMENT"
          value = var.environment
        }
      ]
    }
  ])

  tags = {
    Name = "${var.project_name}-trading-task"
    Environment = var.environment
  }
}

#Banking ECS Service
resource "aws_ecs_service" "banking" {
    name = "${var.project_name}-banking-service"
    cluster = aws_ecs_cluster.cluster.id
    task_definition = aws_ecs_task_definition.banking.arn
    desired_count = var.banking_desired_count
    launch_type = "FARGATE"

    network_configuration {
      subnets = var.private_subnet_ids
      security_groups = [var.banking_sg_id]
      assign_public_ip = false
    }

    load_balancer {
        target_group_arn = var.banking_target_group_arn
        container_name = "banking-api"
        container_port = 8080
    }

    depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]


    tags = {
        Name = "${var.project_name}-banking-service"
        Environment = var.environment
    }
}

#Trading ECS Service
resource "aws_ecs_service" "trading" {
  name = "${var.project_name}-trading-service"
  cluster = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.trading.arn
  desired_count = var.trading_desired_count
  launch_type = "FARGATE"

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [var.trading_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.trading_target_group_arn
    container_name = "trading-api"
    container_port = 8081
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]

  tags = {
    Name = "${var.project_name}-trading-service"
    Environment = var.environment
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "banking" {
  max_capacity = var.banking_max_count
  min_capacity = var.banking_desired_count
  resource_id = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.banking.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "banking_cpu" {
  name = "${var.project_name}-banking-cpu-scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.banking.resource_id
  scalable_dimension = aws_appautoscaling_target.banking.scalable_dimension
  service_namespace = aws_appautoscaling_target.banking.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_target" "trading" {
  max_capacity = var.trading_max_count
  min_capacity = var.trading_desired_count
  resource_id = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.trading.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "trading_cpu" {
  name = "${var.project_name}-trading-cpu-scaling"
  policy_type  = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.trading.resource_id
  scalable_dimension = aws_appautoscaling_target.trading.scalable_dimension
  service_namespace = aws_appautoscaling_target.trading.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# ECR Repository for Banking Service
resource "aws_ecr_repository" "banking" {
  name = "${var.project_name}-banking"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-banking-ecr"
    Environment = var.environment
  }
}

# ECR Repository for Trading Service
resource "aws_ecr_repository" "trading" {
  name = "${var.project_name}-trading"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-trading-ecr"
    Environment = var.environment
  }
}












