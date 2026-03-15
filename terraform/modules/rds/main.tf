#RDS subnet group (Banking)
resource "aws_db_subnet_group" "banking" {
    name = "${var.project_name}-banking-subnet-group "
    subnet_ids = var.private_subnet_ids

    tags = {
        Name = "${var.project_name}-banking-subnet-groups"
        Environment = var.Environment
    }
}

#RDS Subnet Group (Trading)
resource "aws_db_subnet_group" "trading" {
    name = "${var.project_name}-trading-subnet-group"
    subnet_ids = var.private_subnet_ids

    tags = {
        Name = "${var.project_name}-trading-subnet-groups"
        Environment = var.Environment
    }
  
}

#RDS Instance (Banking)
resource "aws_db_instance" "banking" {
    identifier =  "${var.project_name}-banking-db"
    engine = "mysql"
    engine_version = "8.0.27"
    instance_class = var.db_instance_class
    allocated_storage = var.allocated_storage


    db_name = "cnb_banking"
    username = var.banking_db_username
    password = var.banking_db_password

    db_subnet_group_name = aws_db_subnet_group.banking.name
    vpc_security_group_ids = [var.rds_banking_sg_id]

    backup_retention_period = 7
    backup_window           = "03:00-04:00"
    maintenance_window      = "mon:04:00-mon:05:00"

    multi_az = false
    skip_final_snapshot = true
    deletion_protection = false

    tags = {
        Name = "${var.project_name}-banking-db"
        Environment = var.Environment
    }
}
 
# RDS Instance (Trading)
resource "aws_db_instance" "trading" {
  identifier = "${var.project_name}-trading-db"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class
  allocated_storage = var.allocated_storage

  db_name  = "cnb_trading"
  username = var.trading_db_username
  password = var.trading_db_password

  db_subnet_group_name = aws_db_subnet_group.trading.name
  vpc_security_group_ids = [var.rds_trading_sg_id]

  backup_retention_period = 7
  backup_window = "03:00-04:00"
  maintenance_window = "mon:04:00-mon:05:00"

  multi_az = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.project_name}-trading-db"
    Environment = var.Environment
  }
}









