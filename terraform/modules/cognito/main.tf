# Central identity store for all CNB banking and trading users.
# Enforces strong password policy and email verification.
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-user-pool"

  # Password policy — enforces complexity requirements for all user accounts.
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Email verification — users must verify their email before they can sign in.
  auto_verified_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "given_name"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  schema {
    name                = "family_name"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  # Use Cognito's built-in email sending (no SES setup required).
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Advanced security mode enables risk-based adaptive authentication.
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  tags = {
    Name        = "${var.project_name}-user-pool"
    Environment = var.environment
  }
}

# App client used by the React frontend (public SPA — no client secret).
# Supports SRP, password auth, and refresh token flows.
resource "aws_cognito_user_pool_client" "frontend" {
  name         = "${var.project_name}-frontend-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # No secret — public clients (SPAs) cannot securely store a client secret.
  generate_secret = false

  # Auth flows supported by this client.
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # Short-lived access and ID tokens; refresh tokens last 30 days.
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # OAuth 2.0 Authorization Code flow with standard OIDC scopes.
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = ["COGNITO"]

  # Prevent information leakage about whether a username exists.
  prevent_user_existence_errors = "ENABLED"
}

# Hosted-UI domain for OAuth2/OIDC login redirects.
# Provides the /oauth2/authorize, /oauth2/token, etc. endpoints.
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-auth-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# User Groups

# Standard user group — basic banking and trading access.
resource "aws_cognito_user_group" "standard" {
  name         = "standard-users"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Standard CNB users with basic banking and trading access"
  precedence   = 1
}

# Premium user group — elevated feature access.
resource "aws_cognito_user_group" "premium" {
  name         = "premium-users"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Premium CNB users with access to premium features"
  precedence   = 2
}
