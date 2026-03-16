resource "aws_cognito_user_pool" "main" {
    name = "${var.project_name}-user-pool"

    #Password Policy
    password_policy {
      minimum_length = 12
      require_lowercase = true
      require_numbers = true
      require_symbols = true
      require_uppercase = true
      temporary_password_validity_days = 7
    }

    account_recovery_setting {
      recovery_mechanism {
        name = "verified_email"
        priority = 1
      }
    }

    #Email Verification
    auto_verified_attributes = [ "email" ]

    schema {
        name = "email"
        attribute_data_type = "String"
        required = true
        mutable = true
    }

    schema {
        name = "given_name"
        attribute_data_type = "String"
        required = true
        mutable = true
    }

    schema {
        name = "family_name"
        attribute_data_type = "String"
        required = true
        mutable = true
    }

    # Email configuration
    email_configuration {
        email_sending_account = "COGNITO_DEFAULT"
    }

    #User pool add-ons
    user_pool_add_ons {
      advanced_security_mode = "ENFORCED"
    }

    tags = {
      Name = "${var.project_name}-user-pool"
      Environment = var.environment
    }
}

#Cognito User Pool Client (for react frontend)
resource "aws_cognito_user_pool_client" "frontend" {
    name = "${var.project_name}-frontend-client"
    user_pool_id = aws_cognito_user_pool.main.id

    generate_secret = false

  # Auth flows
    explicit_auth_flows = [
        "ALLOW_USER_SRP_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH",
        "ALLOW_USER_PASSWORD_AUTH"
    ]

    #Token Validity
    access_token_validity = 1
    id_token_validity = 1
    refresh_token_validity = 30

    token_validity_units {
        access_token = "hours"
        id_token = "hours"
        refresh_token = "days"
    }

    #OAuth Settings
    allowed_oauth_flows = ["code"]
    allowed_oauth_flows_user_pool_client = true
    allowed_oauth_scopes = ["openid", "email", "profile"]

    callback_urls = var.callback_urls
    logout_urls = var.logout_urls

    supported_identity_providers = [ "COGNITO" ]

    #Prevent user existence issues
    prevent_user_existence_errors = "ENABLED"
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain = "${var.project_name}-auth-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id
}

#Cognito User Pool Domain
resource "aws_cognito_user_group" "standard" {
    name = "standard-users"
    user_pool_id = aws_cognito_user_pool.main.id
    description = "Standard CNB users with basic banking and trading access"
    precedence = 1
}

resource "aws_cognito_user_group" "premium" {
    name = "premium-users"
    user_pool_id = aws_cognito_user_pool.main.id
    description = "Premium CNB users with access to premium features"
    precedence = 2
}