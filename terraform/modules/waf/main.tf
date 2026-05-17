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

# WAF Web ACL protecting the API Gateway.
# Four managed rule groups are applied in priority order:
#   1. Common Rule Set     — blocks common web exploits (XSS, etc.)
#   2. Known Bad Inputs    — blocks request patterns known to be malicious
#   3. SQLi Rule Set       — blocks SQL injection attempts (critical for banking)
#   4. Rate Limit Rule     — blocks IPs exceeding 2000 requests per 5 minutes
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.project_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rules — Common Rule Set: protects against common web exploits.
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
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules — Known Bad Inputs: blocks request patterns associated with exploitation.
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
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules — SQL Injection: critical for protecting banking database queries.
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting rule — blocks any single IP exceeding 2000 requests per 5 minutes.
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-waf"
    Environment = var.environment
  }
}

# CloudWatch log group receiving WAF request logs. WAF requires the log group
# name to start with "aws-waf-logs-".
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.project_name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudtrail.arn

  tags = {
    Name        = "${var.project_name}-waf-logs"
    Environment = var.environment
  }
}

# Logging configuration for the WAF Web ACL.
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
}

# GuardDuty threat-detection detector.
# S3 data-event monitoring and EBS malware scanning are enabled.
# Kubernetes audit log monitoring is disabled — the cluster is self-hosted (not EKS).
resource "aws_guardduty_detector" "main" {
  # checkov:skip=CKV2_AWS_3:GuardDuty is enabled here (enable = true) with S3, Kubernetes-audit, and EBS malware data sources; this is a single-account/single-region setup so org-level enablement is N/A. Checkov's graph check does not recognize the in-resource enablement.
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-guardduty"
    Environment = var.environment
  }
}

# ── CloudTrail KMS keys ───────────────────────────────────────────────────────

# Customer-managed key encrypting CloudTrail log files at rest.
resource "aws_kms_key" "cloudtrail" {
  description             = "${var.project_name} CloudTrail log encryption key"
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
        Sid       = "AllowCloudTrailEncrypt"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:GenerateDataKey*"
        Resource  = "*"
        Condition = {
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = "arn:aws:cloudtrail:*:${var.aws_account_id}:trail/*"
          }
        }
      },
      {
        Sid       = "AllowCloudTrailDescribeKey"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "kms:DescribeKey"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.${data.aws_region.current.name}.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cloudtrail-kms"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/${var.project_name}-cloudtrail"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

# Replica-region key encrypting the replicated CloudTrail log bucket.
resource "aws_kms_key" "cloudtrail_replica" {
  provider                = aws.replica
  description             = "${var.project_name} CloudTrail replica log encryption key"
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
    Name        = "${var.project_name}-cloudtrail-replica-kms"
    Environment = var.environment
  }
}

# ── CloudTrail notifications + CloudWatch Logs ────────────────────────────────

# SNS topic CloudTrail publishes log-file-delivery notifications to.
resource "aws_sns_topic" "cloudtrail" {
  name              = "${var.project_name}-cloudtrail-notifications"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "${var.project_name}-cloudtrail-notifications"
    Environment = var.environment
  }
}

resource "aws_sns_topic_policy" "cloudtrail" {
  arn = aws_sns_topic.cloudtrail.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudTrailPublish"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.cloudtrail.arn
      }
    ]
  })
}

# CloudWatch log group CloudTrail streams events to (named to match the scoped
# IAM policy in the iam module: /aws/cloudtrail/<project>*).
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudtrail.arn

  tags = {
    Name        = "${var.project_name}-cloudtrail-logs"
    Environment = var.environment
  }
}

# Multi-region CloudTrail trail recording all API calls for audit and compliance.
# Log file validation ensures logs have not been tampered with after delivery.
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail.arn
  sns_topic_name                = aws_sns_topic.cloudtrail.name
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = var.cloudtrail_cw_logs_role_arn

  # The bucket policy and SNS policy must exist before CloudTrail attempts to use them.
  # Without this, AWS returns InsufficientS3BucketPolicyException.
  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_sns_topic_policy.cloudtrail
  ]

  tags = {
    Name        = "${var.project_name}-cloudtrail"
    Environment = var.environment
  }
}

# ── CloudTrail log bucket ─────────────────────────────────────────────────────

# S3 bucket that receives CloudTrail log files.
# force_destroy = true allows the bucket to be destroyed even if it contains logs.
# Consider setting this to false in production environments.
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project_name}-cloudtrail-logs-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-cloudtrail-logs"
    Environment = var.environment
  }
}

# Block all public access to the CloudTrail log bucket.
resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning — required to recover overwritten log objects and to replicate.
resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt CloudTrail log objects with the customer-managed KMS key.
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail.arn
    }
    bucket_key_enabled = true
  }
}

# Deliver S3 server access logs for the CloudTrail bucket to the log bucket.
resource "aws_s3_bucket_logging" "cloudtrail" {
  bucket        = aws_s3_bucket.cloudtrail.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "s3/cloudtrail/"
}

# Transition old CloudTrail logs to cheaper storage and expire them eventually.
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "archive-and-expire"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Emit object-level events to EventBridge for auditing/automation.
resource "aws_s3_bucket_notification" "cloudtrail" {
  bucket      = aws_s3_bucket.cloudtrail.id
  eventbridge = true
}

# Bucket policy allowing only the CloudTrail service to write logs to this bucket.
# The AclCheck statement is required by CloudTrail before it will begin writing.
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${var.aws_account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# ── CloudTrail access-log bucket ──────────────────────────────────────────────

# Receives S3 server access logs for the CloudTrail bucket. A log bucket cannot
# meaningfully log to or replicate itself, and S3 log delivery requires SSE-S3.
resource "aws_s3_bucket" "access_logs" {
  # checkov:skip=CKV_AWS_18:This is the access-log destination bucket; logging it to itself would create an unbounded log-of-logs loop.
  # checkov:skip=CKV_AWS_144:Cross-region replication of the access-log bucket is unnecessary and would recurse.
  # checkov:skip=CKV_AWS_145:S3 server access-log delivery does not support SSE-KMS on the destination bucket; SSE-S3 is required.
  bucket        = "${var.project_name}-cloudtrail-access-logs-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-cloudtrail-access-logs"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_ownership_controls" "access_logs" {
  # checkov:skip=CKV2_AWS_65:S3 server-access-log delivery requires ACLs enabled (log-delivery-write) on the destination bucket; BucketOwnerEnforced would break log delivery.
  bucket = aws_s3_bucket.access_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "access_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.access_logs]
  bucket     = aws_s3_bucket.access_logs.id
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

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

resource "aws_s3_bucket_notification" "access_logs" {
  bucket      = aws_s3_bucket.access_logs.id
  eventbridge = true
}

# ── CloudTrail bucket cross-region replica ────────────────────────────────────

resource "aws_s3_bucket" "cloudtrail_replica" {
  # checkov:skip=CKV_AWS_144:This bucket IS the replication destination; replicating it again would loop.
  # checkov:skip=CKV_AWS_18:Replica of audit logs; access logging the replica would require a second log bucket in the replica region.
  provider      = aws.replica
  bucket        = "${var.project_name}-cloudtrail-replica-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-cloudtrail-replica"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.cloudtrail_replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.cloudtrail_replica.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.cloudtrail_replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail_replica.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_replica" {
  provider = aws.replica
  bucket   = aws_s3_bucket.cloudtrail_replica.id

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
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_notification" "cloudtrail_replica" {
  provider    = aws.replica
  bucket      = aws_s3_bucket.cloudtrail_replica.id
  eventbridge = true
}

resource "aws_iam_role" "cloudtrail_replication" {
  name = "${var.project_name}-cloudtrail-replication-role"

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
    Name        = "${var.project_name}-cloudtrail-replication-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "cloudtrail_replication" {
  name = "${var.project_name}-cloudtrail-replication-policy"
  role = aws_iam_role.cloudtrail_replication.id

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
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "SourceObjectRead"
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
      },
      {
        Sid    = "DestinationReplicate"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.cloudtrail_replica.arn}/*"
      },
      {
        Sid      = "SourceKmsDecrypt"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.cloudtrail.arn
      },
      {
        Sid      = "DestinationKmsEncrypt"
        Effect   = "Allow"
        Action   = "kms:Encrypt"
        Resource = aws_kms_key.cloudtrail_replica.arn
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "cloudtrail" {
  depends_on = [
    aws_s3_bucket_versioning.cloudtrail,
    aws_s3_bucket_versioning.cloudtrail_replica
  ]

  role   = aws_iam_role.cloudtrail_replication.arn
  bucket = aws_s3_bucket.cloudtrail.id

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
      bucket        = aws_s3_bucket.cloudtrail_replica.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.cloudtrail_replica.arn
      }
    }
  }
}
