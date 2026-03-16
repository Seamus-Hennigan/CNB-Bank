# WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
    name = "${var.project_name}-waf"
    scope = "REGIONAL"

    default_action {
        allow {}
    }

    # AWS Managed Rules - Common Rule Set
    rule {
        name = "AWSManagedRulesCommonRuleSet"
        priority = 1

        override_action {
        none {}
        }

        statement {
        managed_rule_group_statement {
            name = "AWSManagedRulesCommonRuleSet"
            vendor_name = "AWS"
        }
    }

        visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name = "AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled = true
        }
    }

    # AWS Managed Rules - Known Bad Inputs
    rule {
        name = "AWSManagedRulesKnownBadInputsRuleSet"
        priority = 2

        override_action {
        none {}
        }

        statement {
        managed_rule_group_statement {
            name = "AWSManagedRulesKnownBadInputsRuleSet"
            vendor_name = "AWS"
        }
    }

        visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name = "AWSManagedRulesKnownBadInputsRuleSet"
        sampled_requests_enabled = true
        }
    }

    # AWS Managed Rules - SQL Injection (important for banking)
    rule {
        name = "AWSManagedRulesSQLiRuleSet"
        priority = 3

        override_action {
        none {}
        }

        statement {
        managed_rule_group_statement {
            name = "AWSManagedRulesSQLiRuleSet"
            vendor_name = "AWS"
        }
    }

        visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name = "AWSManagedRulesSQLiRuleSet"
        sampled_requests_enabled = true
    }
  }

# Rate limiting rule
    rule {
        name = "RateLimitRule"
        priority = 4

        action {
        block {}
        }

        statement {
        rate_based_statement {
            limit = 2000
            aggregate_key_type = "IP"
        }
    }

        visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name = "RateLimitRule"
        sampled_requests_enabled = true
        }
    }

    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name = "${var.project_name}-waf"
        sampled_requests_enabled = true
    }

    tags = {
        Name = "${var.project_name}-waf"
        Environment = var.environment
    }
}

# GuardDuty
resource "aws_guardduty_detector" "main" {
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
        Name = "${var.project_name}-guardduty"
        Environment = var.environment
    }
}

# CloudTrail
resource "aws_cloudtrail" "main" {
    name = "${var.project_name}-cloudtrail"
    s3_bucket_name = aws_s3_bucket.cloudtrail.id
    include_global_service_events = true
    is_multi_region_trail = true
    enable_log_file_validation = true

    tags = {
        Name = "${var.project_name}-cloudtrail"
        Environment = var.environment
    }
}

# S3 Bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail" {
    bucket = "${var.project_name}-cloudtrail-logs-${var.environment}"
    force_destroy = true

    tags = {
        Name = "${var.project_name}-cloudtrail-logs"
        Environment = var.environment
    }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
    bucket = aws_s3_bucket.cloudtrail.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
    bucket = aws_s3_bucket.cloudtrail.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Sid = "AWSCloudTrailAclCheck"
            Effect = "Allow"
            Principal = {
            Service = "cloudtrail.amazonaws.com"
            }
            Action = "s3:GetBucketAcl"
            Resource = aws_s3_bucket.cloudtrail.arn
        },
        {
            Sid = "AWSCloudTrailWrite"
            Effect = "Allow"
            Principal = {
            Service = "cloudtrail.amazonaws.com"
            }
            Action = "s3:PutObject"
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