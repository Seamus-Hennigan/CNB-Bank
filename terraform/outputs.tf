# ── Frontend ──────────────────────────────────────────────────────────────────

# CloudFront domain where the React app is served globally over HTTPS.
output "cloudfront_domain" {
  description = "CloudFront distribution domain name for the React frontend"
  value       = module.s3.cloudfront_domain_name
}

# S3 bucket name that holds the built frontend assets — used by CI/CD to sync files.
output "frontend_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend static files"
  value       = module.s3.frontend_bucket_name
}

# ── Auth ──────────────────────────────────────────────────────────────────────

# Cognito User Pool ID — required by the frontend Amplify configuration.
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

# Cognito App Client ID — used by Amplify and referenced in the API Gateway authorizer.
output "cognito_client_id" {
  description = "Cognito User Pool frontend App Client ID"
  value       = module.cognito.frontend_client_id
}

# Hosted-UI domain prefix used for OAuth2 redirect URLs.
output "cognito_domain" {
  description = "Cognito User Pool hosted-UI domain prefix"
  value       = module.cognito.user_pool_domain
}

# ── API Gateway ───────────────────────────────────────────────────────────────

# Base invoke URL for the deployed API stage — all banking and trading requests use this.
output "api_gateway_url" {
  description = "Base invoke URL of the deployed API Gateway stage"
  value       = module.api_gateway.api_gateway_url
}

# ── CI/CD ─────────────────────────────────────────────────────────────────────

# Jenkins access key ID — configure this in Jenkins as an AWS credential.
# Retrieve jenkins_secret_access_key separately via: terraform output -raw jenkins_secret_access_key
output "jenkins_access_key_id" {
  description = "AWS access key ID for the Jenkins CI/CD IAM user"
  value       = module.iam.jenkins_access_key_id
}

# ── Monitoring ────────────────────────────────────────────────────────────────

# Prometheus/Grafana access key ID — configure in the Grafana CloudWatch datasource.
# Retrieve monitoring_secret_access_key separately via: terraform output -raw monitoring_secret_access_key
output "monitoring_access_key_id" {
  description = "AWS access key ID for the Prometheus monitoring IAM user"
  value       = module.iam.monitoring_access_key_id
}

# ── Kubernetes ────────────────────────────────────────────────────────────────

# Kubernetes namespace all CNB workloads run in on the Pi cluster.
output "kubernetes_namespace" {
  description = "Kubernetes namespace for all CNB workloads on the Pi"
  value       = module.kubernetes.namespace
}
