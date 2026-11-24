terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Database Subnet Group & Security Group
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "aurora" {
  name        = "${var.cluster_identifier}-subnet-group"
  description = "Subnet group for Aurora Serverless v2 PostgreSQL cluster"
  subnet_ids  = var.subnet_ids

  tags = {
    Name        = "${var.cluster_identifier}-subnet-group"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_identifier}-sg"
  description = "Allow inbound PostgreSQL traffic from VPC and RDS Proxy"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL ingress from trusted CIDRs"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_identifier}-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Enhanced Monitoring IAM Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.cluster_identifier}-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# -----------------------------------------------------------------------------
# Aurora Serverless v2 PostgreSQL Cluster
# -----------------------------------------------------------------------------
resource "aws_rds_cluster" "aurora" {
  cluster_identifier            = var.cluster_identifier
  engine                        = "aurora-postgresql"
  engine_mode                   = "provisioned"
  engine_version                = var.engine_version
  database_name                 = var.database_name
  master_username               = var.master_username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.cluster.id]

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = "${var.cluster_identifier}-final-snapshot"
  copy_tags_to_snapshot        = true

  enabled_cloudwatch_logs_exports = ["postgresql"]

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  tags = {
    Name        = var.cluster_identifier
    Environment = var.environment
    Engine      = "aurora-postgresql"
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Cluster Instances (Multi-AZ Serverless v2 db.serverless)
# -----------------------------------------------------------------------------
resource "aws_rds_cluster_instance" "instances" {
  count              = var.instance_count
  identifier         = "${var.cluster_identifier}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  publicly_accessible        = false
  auto_minor_version_upgrade = true
  monitoring_interval        = 60
  monitoring_role_arn        = aws_iam_role.rds_enhanced_monitoring.arn

  tags = {
    Name        = "${var.cluster_identifier}-instance-${count.index + 1}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
