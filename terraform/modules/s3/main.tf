#S3 Bucket for React Frontend

resource "aws_s3_bucket" "frontend" {
    bucket = "${var.project_name}-frontend-${var.environment}"

    tags = {
        Name = "${var.project_name}"
        Environment = "${var.environment}"
    }
}

resource  "aws_s3_bucket_versioning" "frontend" {
    bucket = aws_s3_bucket.frontend.id

    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
    bucket = aws_s3_bucket.frontend.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
    bucket = aws_s3_bucket.frontend.id

    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
}

#CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "frontend" {
    name = "${var.project_name}-oac"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "frontend" {
  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"
  comment = "${var.project_name} frontend distribution"

  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id = "S3-${aws_s3_bucket.frontend.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  # Handle React Router paths
  custom_error_response {
    error_code = 404
    response_code = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code = 403
    response_code = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-cloudfront"
    Environment = var.environment
  }
}

#S3 Bucket Policy to allow CloudFront access
resource "aws_s3_bucket_policy" "frontend" {
    bucket = aws_s3_bucket.frontend.id

      policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
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

