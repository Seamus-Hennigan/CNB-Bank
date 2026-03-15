#ALB Security Group

resource "aws_security_group" "alb" {
  name = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id = var.vpc_id


    ingress {
        description = "HTTP from internent"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTPS from internet"
        from_port = 443
        to_port = 443
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0 
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        name = "${var.project_name}-alb-sg"
        Environment = var.environment
    }
}
#Banking Service Security Group
resource "aws_security_group" "banking" {
    name = "${var.project_name}-banking-sg"
    description = "Security group for Banking ECS service"
    vpc_id = var.vpc_id


    ingress {
        description = "HTTP from ALB only"
        from_port = 8080
        to_port = 8080
        protocol = "-1"
        security_groups = [aws_security_group.alb.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "tcp"
        security_groups = [aws_security_group.alb.id]
    }

    tags = {
        Name = "${var.project_name}-banking-sg"
        Environment = var.environment
    }
}

resource "aws_security_group" "trading" {
    name = "${var.project_name}-trading-sg"
    description = "Security group for Trading ECS service"
    vpc_id = var.vpc_id

    ingress {
        description = "HTTP from ALB only"
        from_port = 8081
        to_port = 8081
        protocol = "tcp"
        security_groups = [aws_security_group.alb.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

        tags = {
        Name = "${var.project_name}-trading-sg"
        Environment = var.environment
    }
}

#RDS Banking Security Group
resource  "aws_security_group" "rds_banking" {
    name = "${var.project_name}-rds-banking-sg"
    description = "Security group for RDS Banking instance"
    vpc_id = var.vpc_id

    ingress {
        description = "MySQL from Banking service only"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.banking.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-rds-banking-sg"
        Environment = var.environment
    }
}

#RDS Trading Security Group
resource  "aws_security_group" "rds_trading" {
    name = "${var.project_name}-rds-trading-sg"
    description = "Security group for RDS Trading instance"
    vpc_id = var.vpc_id

    ingress {
        description = "MySQL from Trading service only"
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.trading.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-rds-trading-sg"
        Environment = var.environment
    }
}