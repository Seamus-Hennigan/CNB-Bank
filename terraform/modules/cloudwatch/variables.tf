variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# REST API name from the api_gateway module — scopes API Gateway alarms to this API.
variable "api_gateway_name" {
  description = "Name of the API Gateway REST API"
  type        = string
}

# WAF Web ACL name from the waf module — scopes WAF alarms to this ACL.
variable "waf_acl_name" {
  description = "Name of the WAF Web ACL"
  type        = string
}

# Frontend S3 bucket name from the s3 module — scopes S3 alarms to this bucket.
variable "s3_bucket_name" {
  description = "Name of the frontend S3 bucket"
  type        = string
}
