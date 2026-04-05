# IAM role assumed by the CloudTrail service to write logs to CloudWatch Logs.
resource "aws_iam_role" "cloudtrail" {
  name = "${var.project_name}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-cloudtrail-role"
    Environment = var.environment
  }
}

# Inline policy granting CloudTrail permission to write logs to CloudWatch Logs.
resource "aws_iam_role_policy" "cloudtrail" {
  name = "${var.project_name}-cloudtrail-policy"
  role = aws_iam_role.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM role assumed by GuardDuty to read from S3 and publish threat findings.
resource "aws_iam_role" "guardduty" {
  name = "${var.project_name}-guardduty-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-guardduty-role"
    Environment = var.environment
  }
}

# Dedicated IAM user for the Jenkins CI/CD pipeline.
# Jenkins uses programmatic credentials (access key below) to push images to ECR,
# deploy frontend assets to S3, and invalidate the CloudFront distribution.
resource "aws_iam_user" "jenkins" {
  name = "${var.project_name}-jenkins"

  tags = {
    Name        = "${var.project_name}-jenkins"
    Environment = var.environment
  }
}

# Inline policy granting Jenkins the minimum permissions required for CI/CD:
# ECR image push, S3 frontend deployment, and CloudFront cache invalidation.
# ECS actions have been removed — services now run on self-hosted k3s.
resource "aws_iam_user_policy" "jenkins" {
  name = "${var.project_name}-jenkins-policy"
  user = aws_iam_user.jenkins.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "cloudfront:CreateInvalidation"
        ]
        Resource = "*"
      }
    ]
  })
}

# Programmatic access key for the Jenkins IAM user.
# Store the secret_key output in Jenkins Credentials Manager — never commit it.
resource "aws_iam_access_key" "jenkins" {
  user = aws_iam_user.jenkins.name
}

# Dedicated IAM user for the Prometheus monitoring stack running on the Pi cluster.
# Since Prometheus runs on self-hosted k3s (not EC2), it cannot use an instance role —
# it uses programmatic credentials (access key below) to query AWS CloudWatch metrics.
resource "aws_iam_user" "monitoring" {
  name = "${var.project_name}-monitoring"

  tags = {
    Name        = "${var.project_name}-monitoring"
    Environment = var.environment
  }
}

# Inline policy granting Prometheus read-only access to CloudWatch metrics and log groups.
resource "aws_iam_user_policy" "monitoring" {
  name = "${var.project_name}-monitoring-policy"
  user = aws_iam_user.monitoring.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "logs:DescribeLogGroups",
          "logs:GetLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Programmatic access key for the monitoring IAM user.
# Store the secret_key in Prometheus / Grafana CloudWatch datasource config — never commit it.
resource "aws_iam_access_key" "monitoring" {
  user = aws_iam_user.monitoring.name
}
