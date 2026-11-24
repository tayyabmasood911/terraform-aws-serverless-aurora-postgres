# -----------------------------------------------------------------------------
# RDS Proxy Security Group & IAM Role
# -----------------------------------------------------------------------------
resource "aws_security_group" "proxy" {
  name        = "${var.cluster_identifier}-proxy-sg"
  description = "Security group for Aurora RDS Proxy"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL ingress to RDS Proxy"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow RDS Proxy outbound to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_identifier}-proxy-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group_rule" "cluster_from_proxy" {
  type                     = "ingress"
  description              = "Allow cluster ingress from RDS proxy security group"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.proxy.id
  security_group_id        = aws_security_group.cluster.id
}

resource "aws_iam_role" "proxy" {
  name = "${var.cluster_identifier}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_policy" "proxy_secrets" {
  name        = "${var.cluster_identifier}-proxy-secrets-policy"
  description = "Allow RDS Proxy to read Secrets Manager master password"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "proxy_secrets" {
  role       = aws_iam_role.proxy.name
  policy_arn = aws_iam_policy.proxy_secrets.arn
}

# -----------------------------------------------------------------------------
# RDS Proxy, Target Group & Connection Pool
# -----------------------------------------------------------------------------
resource "aws_db_proxy" "proxy" {
  name                   = "${var.cluster_identifier}-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.proxy.arn
  vpc_security_group_ids = [aws_security_group.proxy.id]
  vpc_subnet_ids         = var.subnet_ids

  auth {
    auth_scheme = "SECRETS"
    description = "Master database user credentials from Secrets Manager"
    iam_auth    = "DISABLED"
    secret_arn  = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
  }

  tags = {
    Name        = "${var.cluster_identifier}-proxy"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_db_proxy_default_target_group" "aurora" {
  db_proxy_name = aws_db_proxy.proxy.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    init_query                   = "SET TIME ZONE 'UTC'"
    max_connections_percent      = 90
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "aurora" {
  db_proxy_name         = aws_db_proxy.proxy.name
  target_group_name     = aws_db_proxy_default_target_group.aurora.name
  db_cluster_identifier = aws_rds_cluster.aurora.id
}
