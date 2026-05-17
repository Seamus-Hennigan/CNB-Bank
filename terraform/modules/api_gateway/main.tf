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

  # Replace the API in place without an outage window when its definition changes.
  lifecycle {
    create_before_destroy = true
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

# Validates that incoming requests carry the required body and query parameters
# before API Gateway forwards them to the backend.
resource "aws_api_gateway_request_validator" "main" {
  name                        = "${var.project_name}-request-validator"
  rest_api_id                 = aws_api_gateway_rest_api.main.id
  validate_request_body       = true
  validate_request_parameters = true
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
  rest_api_id          = aws_api_gateway_rest_api.main.id
  resource_id          = aws_api_gateway_resource.banking_proxy.id
  http_method          = "ANY"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.main.id

  request_parameters = {
    "method.request.path.proxy" = true
  }
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

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
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
  rest_api_id          = aws_api_gateway_rest_api.main.id
  resource_id          = aws_api_gateway_resource.trading_proxy.id
  http_method          = "ANY"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.main.id

  request_parameters = {
    "method.request.path.proxy" = true
  }
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

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
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

# IAM role that lets API Gateway push execution and access logs to CloudWatch Logs.
resource "aws_iam_role" "apigw_cloudwatch" {
  name = "${var.project_name}-apigw-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-apigw-cloudwatch-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch" {
  role       = aws_iam_role.apigw_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Account-level setting that wires API Gateway to the CloudWatch Logs role above.
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# KMS key encrypting the API Gateway access-log group.
resource "aws_kms_key" "api_logs" {
  description             = "${var.project_name} API Gateway access log encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.${data.aws_region.current.name}.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-api-logs-kms"
    Environment = var.environment
  }
}

# CloudWatch log group that receives the stage access logs.
resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/api-gateway/${var.project_name}-api/${var.environment}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.api_logs.arn

  tags = {
    Name        = "${var.project_name}-api-access-logs"
    Environment = var.environment
  }
}

# TLS client certificate API Gateway presents to the backend integration so the
# backend can verify requests originate from this API Gateway stage.
resource "aws_api_gateway_client_certificate" "main" {
  description = "${var.project_name} API Gateway client certificate"

  tags = {
    Name        = "${var.project_name}-api-client-cert"
    Environment = var.environment
  }
}

# Named stage (matches the environment variable) that exposes the deployment
# as a callable URL endpoint at /{stage-name}/.
resource "aws_api_gateway_stage" "main" {
  # checkov:skip=CKV2_AWS_77:The associated WAFv2 Web ACL (var.waf_arn, defined in the waf module) includes the AWSManagedRulesKnownBadInputsRuleSet managed rule group which mitigates the Log4j RCE. Checkov cannot trace the association across the module boundary.
  deployment_id         = aws_api_gateway_deployment.main.id
  rest_api_id           = aws_api_gateway_rest_api.main.id
  stage_name            = var.environment
  cache_cluster_enabled = true
  cache_cluster_size    = "0.5"
  client_certificate_id = aws_api_gateway_client_certificate.main.id
  xray_tracing_enabled  = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name        = "${var.project_name}-api-stage"
    Environment = var.environment
  }

  depends_on = [aws_api_gateway_account.main]
}

# Enables execution logging, metrics, and an encrypted response cache for every
# method on the stage.
resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled      = true
    logging_level        = "ERROR"
    data_trace_enabled   = false
    caching_enabled      = true
    cache_data_encrypted = true
  }
}

# Associates the WAF Web ACL with this API Gateway stage so all inbound traffic
# is inspected before reaching the Cognito authorizer.
resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn  = var.waf_arn
}

# Custom domain name resource that maps api.cnb-bank.org to this API Gateway.
# Uses the Cloudflare Origin CA certificate imported into ACM to authenticate
# the TLS connection from Cloudflare's edge to the regional API Gateway endpoint.
resource "aws_api_gateway_domain_name" "main" {
  domain_name              = var.custom_domain_name
  regional_certificate_arn = var.cloudflare_acm_certificate_arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${var.project_name}-api-domain"
    Environment = var.environment
  }
}

# Maps the deployed API Gateway stage to the custom domain.
# After applying, requests to api.cnb-bank.org are routed to the stage's invoke URL.
resource "aws_api_gateway_base_path_mapping" "main" {
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.main.domain_name
}
