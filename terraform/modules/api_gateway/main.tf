# REST API that acts as the single entry point for all banking and trading requests.
# All traffic is authenticated by Cognito and inspected by WAF before reaching the backend.
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api"
  description = "CNB Banking and Trading API Gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = var.environment
  }
}

# Cognito authorizer that validates the JWT Bearer token in the Authorization header
# against the Cognito User Pool before allowing any request through.
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${var.project_name}-cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [var.user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# /banking path segment — parent resource for all banking API routes.
resource "aws_api_gateway_resource" "banking" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "banking"
}

# Greedy proxy resource that captures all sub-paths under /banking/{proxy+}.
resource "aws_api_gateway_resource" "banking_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.banking.id
  path_part   = "{proxy+}"
}

# ANY method on the banking proxy resource — requires a valid Cognito JWT token.
resource "aws_api_gateway_method" "banking_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.banking_proxy.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# HTTP_PROXY integration that forwards the full request to the banking service
# running on the Raspberry Pi k3s cluster via the Cloudflare Tunnel.
resource "aws_api_gateway_integration" "banking_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.banking_proxy.id
  http_method             = aws_api_gateway_method.banking_proxy.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "https://${var.cloudflare_tunnel_url}/api/banking/{proxy}"
}

# /trading path segment — parent resource for all trading API routes.
resource "aws_api_gateway_resource" "trading" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "trading"
}

# Greedy proxy resource that captures all sub-paths under /trading/{proxy+}.
resource "aws_api_gateway_resource" "trading_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.trading.id
  path_part   = "{proxy+}"
}

# ANY method on the trading proxy resource — requires a valid Cognito JWT token.
resource "aws_api_gateway_method" "trading_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.trading_proxy.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# HTTP_PROXY integration that forwards the full request to the trading service
# running on the Raspberry Pi k3s cluster via the Cloudflare Tunnel.
resource "aws_api_gateway_integration" "trading_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.trading_proxy.id
  http_method             = aws_api_gateway_method.trading_proxy.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "https://${var.cloudflare_tunnel_url}/api/trading/{proxy}"
}

# Deployment snapshot of the current API configuration.
# create_before_destroy ensures a new deployment is created before the old one
# is destroyed, preventing downtime when the API is redeployed.
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

# Named stage (matches the environment variable) that exposes the deployment
# as a callable URL endpoint at /{stage-name}/.
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  tags = {
    Name        = "${var.project_name}-api-stage"
    Environment = var.environment
  }
}

# Associates the WAF Web ACL with this API Gateway stage so all inbound traffic
# is inspected before reaching the Cognito authorizer.
resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn  = var.waf_arn
}
