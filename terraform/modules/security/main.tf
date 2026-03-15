#ALB Security Group

resource "aws_security_group" "alb" {
  Name = "${var.project_Name}-alb-sg"
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
        Name = "${var.project_Name}-alb-sg"
        Environment = var.Environment
    }
}
#Banking Service Security Group
resource "aws_security_group" "banking" {
    Name = "${var.project_Name}-banking-sg"
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
        Name = "${var.project_Name}-banking-sg"
        Environment = var.Environment
    }
}

resource "aws_security_group" "trading" {
    Name = "${var.project_Name}-trading-sg"
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
        Name = "${var.project_Name}-trading-sg"
        Environment = var.Environment
    }
}

#RDS Banking Security Group
resource  "aws_security_group" "rds_banking" {
    Name = "${var.project_Name}-rds-banking-sg"
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
        Name = "${var.project_Name}-rds-banking-sg"
        Environment = var.Environment
    }
}

#RDS Trading Security Group
resource  "aws_security_group" "rds_trading" {
    Name = "${var.project_Name}-rds-trading-sg"
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
        Name = "${var.project_Name}-rds-trading-sg"
        Environment = var.Environment
    }
}