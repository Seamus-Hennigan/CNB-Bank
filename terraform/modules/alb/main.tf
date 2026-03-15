#Application Load Balancer
resource "aws_lb" "main" {
    name = "${var.project_name}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [var.alb_sg_id]
    subnets = var.public_subnet_ids

    enable_deletion_protection = false

    tags = {
      Name = "${var.project_name}-alb"
      Environment = var.Environment  
    }
}

#Banking Target Group
resource "aws_lb_target_group" "banking" {
    name = "${var.project_name}-banking-tg"
    port = 8080
    protocol = "HTTP"
    vpc_id = var.vpc_id
    target_type = "ip"


    health_check {
        enabled = true
        healthy_threshold = 2
        unhealthy_threshold = 3
        timeout = 5
        interval = 30
        path = "/health"
        matcher = "200"
    }

    tags = {
        Name = "${var.project_name}-banking-tg"
        Environment = var.Environment  
    }
}

#Trading Target Group
resource "aws_lb_target_group" "trading" {
    name = "${var.project_name}-trading-tg"
    port = 8081
    protocol = "HTTP"
    vpc_id = var.vpc_id
    target_type = "ip"

    health_check {
      enabled = true
      healthy_threshold = 2
      unhealthy_threshold = 3
      timeout = 5
      interval = 30
      path = "/health"
      matcher = "200"
    }
    
    tags = {
        Name = "${var.project_name}-trading-tg"
        Environment = var.Environment  
    }
}

#HTTP Llistener (redirects to HTTPS)
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.main.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "redirect"
    

        redirect {
            port = "443"
            protocol = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}

#Routing rule for banking
resource "aws_lb_listener_rule" "banking" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.banking.arn
    }

    condition {
      path_pattern {
        values = [ "/api/banking/*" ]
      }
    }
}

#Routing rule for trading
resource "aws_lb_listener_rule" "trading" {
    listener_arn = aws_lb_listener.http.arn
    priority = 200

    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.trading.arn
    }

    condition {
      path_pattern {
        values = [ "/api/trading/*" ]
      }
    }
}



