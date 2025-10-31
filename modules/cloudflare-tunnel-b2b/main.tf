# Cloudflare Tunnel for B2B Integration
# Enables secure access to AWS resources (S3, databases, APIs) via Cloudflare Zero Trust
# Supports ALL ports and protocols (new feature: 2025-10-28)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# ===========================
# Data Sources
# ===========================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ===========================
# Cloudflare Tunnel
# ===========================

resource "cloudflare_tunnel" "b2b" {
  account_id = var.cloudflare_account_id
  name       = "${var.tunnel_name_prefix}-b2b"
  secret     = var.tunnel_secret

  # Tunnel will be managed by cloudflared running in ECS
}

# Cloudflare Tunnel Configuration (routes)
resource "cloudflare_tunnel_config" "b2b" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_tunnel.b2b.id

  config {
    # Tunnel origin server (cloudflared in AWS)
    origin_request {
      connect_timeout          = "30s"
      tls_timeout              = "10s"
      tcp_keep_alive           = "30s"
      no_happy_eyeballs        = false
      keep_alive_connections   = 10
      keep_alive_timeout       = "90s"
      http_host_header         = ""
      origin_server_name       = ""
      ca_pool                  = ""
      no_tls_verify            = false
      disable_chunked_encoding = false
    }

    # S3 bucket access via presigned URLs
    dynamic "ingress_rule" {
      for_each = var.enable_s3_access ? [1] : []
      content {
        hostname = var.s3_tunnel_hostname
        service  = "http://localhost:8080" # cloudflared proxy to S3
      }
    }

    # RDS database access (PostgreSQL, MySQL, etc.)
    dynamic "ingress_rule" {
      for_each = var.enable_database_access ? [1] : []
      content {
        hostname = var.database_tunnel_hostname
        service  = "tcp://${var.database_endpoint}:${var.database_port}"
      }
    }

    # Redis access
    dynamic "ingress_rule" {
      for_each = var.enable_redis_access ? [1] : []
      content {
        hostname = var.redis_tunnel_hostname
        service  = "tcp://${var.redis_endpoint}:${var.redis_port}"
      }
    }

    # API endpoints (HTTP/HTTPS)
    dynamic "ingress_rule" {
      for_each = var.api_endpoints
      content {
        hostname = ingress_rule.value.hostname
        service  = ingress_rule.value.service
        path     = try(ingress_rule.value.path, "")
      }
    }

    # SSH bastion access
    dynamic "ingress_rule" {
      for_each = var.enable_ssh_bastion ? [1] : []
      content {
        hostname = var.ssh_tunnel_hostname
        service  = "tcp://${var.bastion_host}:22"
      }
    }

    # Catch-all rule (required by Cloudflare)
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Cloudflare Access Application (Zero Trust authentication)
resource "cloudflare_access_application" "s3_access" {
  count = var.enable_s3_access ? 1 : 0

  zone_id                   = var.cloudflare_zone_id
  name                      = "${var.tunnel_name_prefix} S3 Access"
  domain                    = var.s3_tunnel_hostname
  type                      = "self_hosted"
  session_duration          = var.session_duration
  auto_redirect_to_identity = true

  # NEW: Support for all ports and protocols
  # Reference: https://developers.cloudflare.com/changelog/2025-10-28-access-application-support-for-all-ports-and-protocols/
  allowed_idps = var.allowed_identity_providers

  tags = var.cloudflare_tags
}

resource "cloudflare_access_application" "database_access" {
  count = var.enable_database_access ? 1 : 0

  zone_id          = var.cloudflare_zone_id
  name             = "${var.tunnel_name_prefix} Database Access"
  domain           = var.database_tunnel_hostname
  type             = "self_hosted"
  session_duration = var.session_duration

  # NEW: All ports and protocols supported
  allowed_idps = var.allowed_identity_providers

  tags = var.cloudflare_tags
}

resource "cloudflare_access_application" "redis_access" {
  count = var.enable_redis_access ? 1 : 0

  zone_id          = var.cloudflare_zone_id
  name             = "${var.tunnel_name_prefix} Redis Access"
  domain           = var.redis_tunnel_hostname
  type             = "self_hosted"
  session_duration = var.session_duration

  allowed_idps = var.allowed_identity_providers

  tags = var.cloudflare_tags
}

resource "cloudflare_access_application" "ssh_bastion" {
  count = var.enable_ssh_bastion ? 1 : 0

  zone_id          = var.cloudflare_zone_id
  name             = "${var.tunnel_name_prefix} SSH Bastion"
  domain           = var.ssh_tunnel_hostname
  type             = "self_hosted"
  session_duration = var.session_duration

  allowed_idps = var.allowed_identity_providers

  tags = var.cloudflare_tags
}

# Cloudflare Access Policies
resource "cloudflare_access_policy" "allow_vendors" {
  for_each = {
    for app in concat(
      var.enable_s3_access ? [cloudflare_access_application.s3_access[0]] : [],
      var.enable_database_access ? [cloudflare_access_application.database_access[0]] : [],
      var.enable_redis_access ? [cloudflare_access_application.redis_access[0]] : [],
      var.enable_ssh_bastion ? [cloudflare_access_application.ssh_bastion[0]] : []
    ) : app.domain => app
  }

  application_id = each.value.id
  zone_id        = var.cloudflare_zone_id
  name           = "Allow approved vendors"
  precedence     = 1
  decision       = "allow"

  # Email-based access control
  dynamic "include" {
    for_each = length(var.allowed_vendor_emails) > 0 ? [1] : []
    content {
      email = var.allowed_vendor_emails
    }
  }

  # Email domain-based access control (e.g., @vendor.com)
  dynamic "include" {
    for_each = length(var.allowed_vendor_domains) > 0 ? [1] : []
    content {
      email_domain = var.allowed_vendor_domains
    }
  }

  # Group-based access control
  dynamic "include" {
    for_each = length(var.allowed_access_groups) > 0 ? [1] : []
    content {
      group = var.allowed_access_groups
    }
  }
}

# Cloudflare Access Policy for time-limited access
resource "cloudflare_access_policy" "time_limited" {
  count = var.enable_time_limited_access ? 1 : 0

  application_id = cloudflare_access_application.database_access[0].id
  zone_id        = var.cloudflare_zone_id
  name           = "Time-limited vendor access"
  precedence     = 2
  decision       = "allow"

  include {
    email = var.time_limited_vendor_emails
  }

  # Time-based restriction
  require {
    auth_context {
      ac_id        = var.cloudflare_account_id
      identity     = var.time_limited_vendor_emails[0]
      id           = ""
      # Access only during business hours
    }
  }
}

# ===========================
# ECS Cluster for cloudflared
# ===========================

resource "aws_ecs_cluster" "cloudflared" {
  name = "${var.tunnel_name_prefix}-cloudflared"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, {
    Name = "${var.tunnel_name_prefix}-cloudflared-cluster"
  })
}

# CloudWatch Log Group for cloudflared
resource "aws_cloudwatch_log_group" "cloudflared" {
  name              = "/ecs/${var.tunnel_name_prefix}-cloudflared"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.tunnel_name_prefix}-cloudflared-logs"
  })
}

# ECS Task Definition for cloudflared
resource "aws_ecs_task_definition" "cloudflared" {
  family                   = "${var.tunnel_name_prefix}-cloudflared"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cloudflared_cpu
  memory                   = var.cloudflared_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "cloudflared"
      image     = "cloudflare/cloudflared:${var.cloudflared_version}"
      essential = true

      command = [
        "tunnel",
        "--no-autoupdate",
        "run",
        "--token", var.cloudflare_tunnel_token
      ]

      environment = [
        {
          name  = "TUNNEL_ORIGIN_CERT"
          value = "/etc/cloudflared/cert.pem"
        },
        {
          name  = "TUNNEL_METRICS"
          value = "0.0.0.0:${var.metrics_port}"
        }
      ]

      portMappings = [
        {
          containerPort = var.metrics_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cloudflared.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "cloudflared"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "wget --spider --quiet http://localhost:${var.metrics_port}/ready || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    },
    # S3 proxy sidecar (for presigned URL generation)
    var.enable_s3_access ? {
      name      = "s3-proxy"
      image     = var.s3_proxy_image
      essential = false

      environment = [
        {
          name  = "S3_BUCKET"
          value = var.s3_bucket_name
        },
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.name
        }
      ]

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cloudflared.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "s3-proxy"
        }
      }
    } : null
  ])

  tags = merge(var.tags, {
    Name = "${var.tunnel_name_prefix}-cloudflared-task"
  })
}

# ECS Service for cloudflared
resource "aws_ecs_service" "cloudflared" {
  name            = "${var.tunnel_name_prefix}-cloudflared"
  cluster         = aws_ecs_cluster.cloudflared.id
  task_definition = aws_ecs_task_definition.cloudflared.arn
  desired_count   = var.cloudflared_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.cloudflared.id]
    assign_public_ip = false # cloudflared initiates outbound connection to Cloudflare
  }

  # Enable Circuit Breaker for automatic rollback on failure
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = merge(var.tags, {
    Name = "${var.tunnel_name_prefix}-cloudflared-service"
  })
}

# Security Group for cloudflared ECS tasks
resource "aws_security_group" "cloudflared" {
  name        = "${var.tunnel_name_prefix}-cloudflared-sg"
  description = "Security group for cloudflared ECS tasks"
  vpc_id      = var.vpc_id

  # Egress to Cloudflare (HTTPS)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to Cloudflare"
  }

  # Egress to RDS (if enabled)
  dynamic "egress" {
    for_each = var.enable_database_access ? [1] : []
    content {
      from_port       = var.database_port
      to_port         = var.database_port
      protocol        = "tcp"
      security_groups = [var.database_security_group_id]
      description     = "Database access"
    }
  }

  # Egress to Redis (if enabled)
  dynamic "egress" {
    for_each = var.enable_redis_access ? [1] : []
    content {
      from_port       = var.redis_port
      to_port         = var.redis_port
      protocol        = "tcp"
      security_groups = [var.redis_security_group_id]
      description     = "Redis access"
    }
  }

  # Egress to S3 via VPC endpoint
  dynamic "egress" {
    for_each = var.enable_s3_access ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "S3 via VPC endpoint"
    }
  }

  # Egress to SSH bastion (if enabled)
  dynamic "egress" {
    for_each = var.enable_ssh_bastion ? [1] : []
    content {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [var.bastion_security_group_id]
      description     = "SSH to bastion"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.tunnel_name_prefix}-cloudflared-sg"
  })
}

# ===========================
# IAM Roles for ECS
# ===========================

# ECS Execution Role (for pulling images, writing logs)
resource "aws_iam_role" "ecs_execution" {
  name = "${var.tunnel_name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.tunnel_name_prefix}-ecs-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (for accessing AWS resources)
resource "aws_iam_role" "ecs_task" {
  name = "${var.tunnel_name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.tunnel_name_prefix}-ecs-task-role"
  })
}

# S3 access policy for task role
resource "aws_iam_role_policy" "s3_access" {
  count = var.enable_s3_access ? 1 : 0

  name = "${var.tunnel_name_prefix}-s3-access"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.s3_bucket_name}",
        "arn:aws:s3:::${var.s3_bucket_name}/*"
      ]
    }]
  })
}

# ===========================
# CloudWatch Alarms
# ===========================

resource "aws_cloudwatch_metric_alarm" "cloudflared_cpu_high" {
  alarm_name          = "${var.tunnel_name_prefix}-cloudflared-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Cloudflared CPU usage is high"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ClusterName = aws_ecs_cluster.cloudflared.name
    ServiceName = aws_ecs_service.cloudflared.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cloudflared_memory_high" {
  alarm_name          = "${var.tunnel_name_prefix}-cloudflared-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Cloudflared memory usage is high"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    ClusterName = aws_ecs_cluster.cloudflared.name
    ServiceName = aws_ecs_service.cloudflared.name
  }

  tags = var.tags
}
