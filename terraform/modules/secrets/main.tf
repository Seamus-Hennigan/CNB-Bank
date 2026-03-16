#Banking DB Secret
resource "aws_secretsmanager_secret" "banking_db" {
    name = "${var.project_name}/banking/db-credentials"
    description = "Banking service database credentials"

    recovery_window_in_days = 7


    tags = {
      Name = "${var.project_name}-banking-db-secret"
      Environment = var.environment
    }
}

resource "aws_secretsmanager_secret_version" "banking_db" {
    secret_id = aws_secretsmanager_secret.banking_db.id

  secret_string = jsonencode({
    host = var.banking_db_endpoint
    dbname = var.banking_db_name
    username = var.banking_db_username
    password = var.banking_db_password
    port = "3306"
  })
}

#Trading DB Secret
resource "aws_secretsmanager_secret" "trading_db" {
    name = "${var.project_name}/trading/db-credentials"
    description = "Trading service database credentials"

    recovery_window_in_days = 7

    tags = {
        Name = "${var.project_name}-trading-db-secret"
        Environment = var.environment
    }
}

resource "aws_secretsmanager_secret_version" "trading_db" {
    secret_id = aws_secretsmanager_secret.trading_db.id

    secret_string = jsonencode({
        host = var.trading_db_endpoint
        dbname = var.trading_db_name
        username = var.trading_db_username
        password = var.trading_db_password
        port = "3306"
    })
}

# Stock Market API Key Secret 
resource "aws_secretsmanager_secret" "stock_api" {
    name = "${var.project_name}/trading/stock-api-key"
    description = "Stock market API key for market data ingestion"

    recovery_window_in_days = 7

    tags = {
        Name = "${var.project_name}-stock-api-secret"
        Environment = var.environment
    }
}

resource "aws_secretsmanager_secret_version" "stock_api" {
    secret_id = aws_secretsmanager_secret.stock_api.id

    secret_string = jsonencode({
        api_key = var.stock_api_key
    })
}



