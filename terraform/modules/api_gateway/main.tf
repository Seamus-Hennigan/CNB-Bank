#API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
    name = "${var.project_name}-api"
    description = "CNB Banking and Trading API Gateway"

    endpoint_configuration {
      types = ["REGIONAL"]
    }

    tags = {
      Name = "${var.project_name}-api"
      Environment = var.environment
    }
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name = "${var.project_name}-cognito-authorizer"
  rest_api_id = aws_api_gateway_rest_api.main.id
  type = "COGNITO_USER_POOLS"
  provider_arns = [var.user_pool_arn]

  identity_source = "method.request.header.Authorization"
}

#Banking Resource
resource "aws_api_gateway_resource" "banking" {
    rest_api_id = aws_api_gateway_rest_api.main.id
    parent_id = aws_api_gateway_rest_api.main.root_resource_id
    path_part = "banking"
}

resource "aws_api_gateway_resource" "banking_proxy" {
    rest_api_id = aws_api_gateway_rest_api.main.id
    parent_id = aws_api_gateway_resource.banking.id
    path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "banking_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.banking_proxy.id
  http_method = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "banking_proxy" {
    rest_api_id = aws_api_gateway_rest_api.main.id
    resource_id = aws_api_gateway_resource.banking_proxy.id
    http_method = aws_api_gateway_method.banking_proxy.http_method
    type = "HTTP_PROXY"
    integration_http_method = "ANY"
    uri = "https://${var.cloudflare_tunnel_url}/api/banking/{proxy}"
}

#Trading Resource
resource "aws_api_gateway_resource" "trading" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id = aws_api_gateway_rest_api.main.root_resource_id
  path_part = "trading"
}

resource "aws_api_gateway_resource" "trading_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id = aws_api_gateway_resource.trading.id
  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "trading_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.trading_proxy.id
  http_method = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "trading_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.trading_proxy.id
  http_method = aws_api_gateway_method.trading_proxy.http_method
  type = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri = "https://${var.cloudflare_tunnel_url}/api/trading/{proxy}"
}

#Deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  depends_on = [
    aws_api_gateway_integration.banking_proxy,
    aws_api_gateway_integration.trading_proxy
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name = var.environment

  tags = {
    Name = "${var.project_name}-api-stage"
    Environment = var.environment
  }
}

#WAF Association
resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn = var.waf_arn
}