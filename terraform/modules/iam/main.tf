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

# Inline policy granting CloudTrail permission to write logs to the dedicated
# CloudTrail CloudWatch log group only — scoped to that group's ARN rather than "*".
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
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/cloudtrail/${var.project_name}*:*"
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
  # checkov:skip=CKV_AWS_273:Jenkins is a machine/CI principal; no SSO/IdP exists in this environment, so a scoped long-lived IAM user is the only viable auth mechanism for the self-hosted Jenkins controller.
  name = "${var.project_name}-jenkins"

  tags = {
    Name        = "${var.project_name}-jenkins"
    Environment = var.environment
  }
}

# Inline policy granting Jenkins the minimum permissions required for CI/CD:
# ECR image push, S3 frontend deployment, and CloudFront cache invalidation.
# Every statement is scoped to specific resource ARNs (no "*" resources except for
# ecr:GetAuthorizationToken, which AWS does not support resource-level scoping for).
resource "aws_iam_user_policy" "jenkins" {
  # checkov:skip=CKV_AWS_40:Jenkins is a single-purpose machine identity needing dedicated credentials; a group adds management indirection without changing the (already least-privilege) effective permissions.
  name = "${var.project_name}-jenkins-policy"
  user = aws_iam_user.jenkins.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "EcrPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [
          "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${var.project_name}-banking",
          "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${var.project_name}-trading"
        ]
      },
      {
        Sid    = "S3FrontendObjects"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-frontend-${var.environment}/*"
      },
      {
        Sid      = "S3FrontendList"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${var.project_name}-frontend-${var.environment}"
      },
      {
        Sid      = "CloudFrontInvalidation"
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = "arn:aws:cloudfront::${var.aws_account_id}:distribution/*"
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
  # checkov:skip=CKV_AWS_273:Prometheus runs on the self-hosted Pi cluster (not EC2, no instance role) and no SSO/IdP exists; a scoped read-only IAM user is the only viable mechanism.
  name = "${var.project_name}-monitoring"

  tags = {
    Name        = "${var.project_name}-monitoring"
    Environment = var.environment
  }
}

# Inline policy granting Prometheus read-only access to CloudWatch metrics and log
# groups. Account-wide list/describe actions that AWS does not support resource-level
# scoping for use "*"; the remaining actions are scoped to this account/region.
resource "aws_iam_user_policy" "monitoring" {
  # checkov:skip=CKV_AWS_40:The monitoring user is a single-purpose machine identity needing dedicated read-only credentials; a group adds indirection without changing effective permissions.
  name = "${var.project_name}-monitoring-policy"
  user = aws_iam_user.monitoring.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchRead"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "tag:GetResources",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Sid      = "CloudWatchAlarms"
        Effect   = "Allow"
        Action   = "cloudwatch:DescribeAlarms"
        Resource = "arn:aws:cloudwatch:${var.aws_region}:${var.aws_account_id}:alarm:*"
      },
      {
        Sid      = "CloudWatchLogEvents"
        Effect   = "Allow"
        Action   = "logs:GetLogEvents"
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:*:log-stream:*"
      }
    ]
  })
}

# Programmatic access key for the monitoring IAM user.
# Store the secret_key in Prometheus / Grafana CloudWatch datasource config — never commit it.
resource "aws_iam_access_key" "monitoring" {
  user = aws_iam_user.monitoring.name
}
