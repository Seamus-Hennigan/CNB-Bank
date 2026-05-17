# This module manages a frontend bucket replicated cross-region, fronted by a
# WAF-protected CloudFront distribution, plus the supporting log/replica buckets.
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.replica]
    }
  }
}

data "aws_region" "current" {}

data "aws_region" "replica" {
  provider = aws.replica
}

# ── KMS keys ──────────────────────────────────────────────────────────────────

# Customer-managed key encrypting the frontend bucket. The key policy lets the
# account delegate access via IAM (for Jenkins uploads) and lets CloudFront
# decrypt objects it serves through the OAC.
resource "aws_kms_key" "frontend" {
  description             = "${var.project_name} frontend S3 encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowS3CallersViaService"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
      {
        Sid       = "AllowCloudFrontDecrypt"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${var.aws_account_id}:distribution/${aws_cloudfront_distribution.frontend.id}"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-frontend-kms"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "frontend" {
  name          = "alias/${var.project_name}-frontend"
  target_key_id = aws_kms_key.frontend.key_id
}

# Customer-managed key in the replica region encrypting the replica bucket.
resource "aws_kms_key" "replica" {
  provider                = aws.replica
  description             = "${var.project_name} frontend replica S3 encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowS3CallersViaService"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${data.aws_region.replica.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-frontend-replica-kms"
    Environment = var.environment
  }
}

# ── Access-log bucket ─────────────────────────────────────────────────────────

# Receives S3 server access logs and CloudFront standard access logs.
# CloudFront/S3 log delivery requires ACLs enabled and SSE-S3 (not SSE-KMS), and a
# log bucket cannot meaningfully log to or replicate itself — hence the scoped skips.
resource "aws_s3_bucket" "logs" {
  # checkov:skip=CKV_AWS_18:This is the access-log destination bucket; logging it to itself would create an unbounded log-of-logs loop.
  # checkov:skip=CKV_AWS_144:Cross-region replication of the access-log bucket is unnecessary and would recurse (the replica would also need a log/replica bucket).
  # checkov:skip=CKV_AWS_145:CloudFront/S3 standard access-log delivery does not support SSE-KMS on the destination bucket; SSE-S3 is required.
  bucket        = "${var.project_name}-access-logs-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-access-logs"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  # checkov:skip=CKV2_AWS_65:CloudFront standard log delivery and S3 server-access-log delivery require ACLs enabled (log-delivery-write) on the destination bucket; BucketOwnerEnforced would break log delivery.
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_notification" "logs" {
  bucket      = aws_s3_bucket.logs.id
  eventbridge = true
}

# ── Frontend bucket ───────────────────────────────────────────────────────────

# S3 bucket storing the compiled React frontend static files.
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"

  tags = {
    Name        = "${var.project_name}"
    Environment = "${var.environment}"
  }
}

# Enable versioning so previous frontend builds can be recovered (also required
# as the source of cross-region replication).
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block all direct public access — only CloudFront is allowed to read objects.
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt all objects at rest with the customer-managed KMS key.
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.frontend.arn
    }
    bucket_key_enabled = true
  }
}

# Deliver S3 server access logs to the dedicated log bucket.
resource "aws_s3_bucket_logging" "frontend" {
  bucket        = aws_s3_bucket.frontend.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3/frontend/"
}

# Expire old noncurrent frontend builds and clean up incomplete multipart uploads.
resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "expire-old-builds"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Emit object-level events to EventBridge for auditing/automation.
resource "aws_s3_bucket_notification" "frontend" {
  bucket      = aws_s3_bucket.frontend.id
  eventbridge = true
}

# ── Replica bucket (cross-region replication destination) ─────────────────────

resource "aws_s3_bucket" "frontend_replica" {
  # checkov:skip=CKV_AWS_144:This bucket IS the replication destination; replicating it again would loop.
  # checkov:skip=CKV_AWS_18:Replica of static frontend assets; access logging the replica is not required and would need a second log bucket in the replica region.
  provider      = aws.replica
  bucket        = "${var.project_name}-frontend-replica-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-frontend-replica"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "frontend_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.frontend_replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.frontend_replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.frontend_replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.replica.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.frontend_replica.id

  rule {
    id     = "expire-old-builds"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_notification" "frontend_replica" {
  provider    = aws.replica
  bucket      = aws_s3_bucket.frontend_replica.id
  eventbridge = true
}

# ── Replication role + configuration ──────────────────────────────────────────

resource "aws_iam_role" "replication" {
  name = "${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-s3-replication-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "replication" {
  name = "${var.project_name}-s3-replication-policy"
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SourceBucketRead"
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.frontend.arn
      },
      {
        Sid    = "SourceObjectRead"
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      },
      {
        Sid    = "DestinationReplicate"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.frontend_replica.arn}/*"
      },
      {
        Sid      = "SourceKmsDecrypt"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.frontend.arn
      },
      {
        Sid      = "DestinationKmsEncrypt"
        Effect   = "Allow"
        Action   = "kms:Encrypt"
        Resource = aws_kms_key.replica.arn
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "frontend" {
  depends_on = [
    aws_s3_bucket_versioning.frontend,
    aws_s3_bucket_versioning.frontend_replica
  ]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.frontend_replica.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.replica.arn
      }
    }
  }
}

# ── CloudFront ────────────────────────────────────────────────────────────────

# OAC allows CloudFront to sign S3 requests without making the bucket public.
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Adds standard security response headers (HSTS, nosniff, frame-deny, etc.) to
# every response CloudFront returns.
resource "aws_cloudfront_response_headers_policy" "frontend" {
  name = "${var.project_name}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
}

# CLOUDFRONT-scoped WAFv2 Web ACL protecting the distribution. Includes the
# Known Bad Inputs managed rule group, which mitigates the Log4j RCE.
resource "aws_wafv2_web_acl" "cloudfront" {
  name  = "${var.project_name}-cloudfront-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "cloudfrontCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "cloudfrontKnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-cloudfront-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-cloudfront-waf"
    Environment = var.environment
  }
}

# KMS key encrypting the CloudFront WAF log group.
resource "aws_kms_key" "logs" {
  description             = "${var.project_name} CloudFront WAF log group encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
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
    Name        = "${var.project_name}-cloudfront-waf-logs-kms"
    Environment = var.environment
  }
}

# CloudWatch log group + logging configuration for the CloudFront WAF.
resource "aws_cloudwatch_log_group" "cloudfront_waf" {
  name              = "aws-waf-logs-${var.project_name}-cloudfront"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.logs.arn

  tags = {
    Name        = "${var.project_name}-cloudfront-waf-logs"
    Environment = var.environment
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  log_destination_configs = [aws_cloudwatch_log_group.cloudfront_waf.arn]
  resource_arn            = aws_wafv2_web_acl.cloudfront.arn
}

# CloudFront distribution serving the React SPA globally over HTTPS.
# 404 and 403 errors are rewritten to index.html to support React Router client-side routing.
resource "aws_cloudfront_distribution" "frontend" {
  # checkov:skip=CKV_AWS_174:Client TLS is terminated by Cloudflare (modern TLS 1.2/1.3) in front of this distribution; a custom ACM viewer certificate requires distribution aliases and cross-module Cloudflare DNS validation that is out of scope here.
  # checkov:skip=CKV2_AWS_42:Same as CKV_AWS_174 — the viewer certificate is intentionally the CloudFront default cert for the Cloudflare-fronted origin hop.
  # checkov:skip=CKV2_AWS_47:The attached aws_wafv2_web_acl.cloudfront includes AWSManagedRulesKnownBadInputsRuleSet (mitigates Log4j RCE); Checkov's graph check does not resolve the web_acl_id ARN reference to the rule group.
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "${var.project_name} frontend distribution"
  web_acl_id          = aws_wafv2_web_acl.cloudfront.arn

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-primary"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  origin {
    domain_name              = aws_s3_bucket.frontend_replica.bucket_regional_domain_name
    origin_id                = "S3-replica"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  # Fail over to the cross-region replica bucket if the primary origin is unavailable.
  origin_group {
    origin_id = "S3-failover-group"

    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }

    member {
      origin_id = "S3-primary"
    }

    member {
      origin_id = "S3-replica"
    }
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-failover-group"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.frontend.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Rewrite 404s to index.html so React Router can handle the path client-side.
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Rewrite 403s (S3 access denied for missing keys) the same way.
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Standard access logs delivered to the dedicated log bucket.
  logging_config {
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    include_cookies = false
    prefix          = "cloudfront/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["CU", "IR", "KP", "RU", "SY"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.project_name}-cloudfront"
    Environment = var.environment
  }
}

# Bucket policy restricting S3 reads to the specific CloudFront distribution via OAC.
# Without this policy the bucket objects are inaccessible even through CloudFront.
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}

# Same OAC-scoped read policy for the replica bucket so CloudFront can fail over to it.
resource "aws_s3_bucket_policy" "frontend_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.frontend_replica.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend_replica.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}
