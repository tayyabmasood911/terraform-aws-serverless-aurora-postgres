variable "aws_region" {
  type        = string
  description = "Target AWS deployment region"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., production, staging)"
  default     = "production"
}

variable "cluster_identifier" {
  type        = string
  description = "Unique identifier name for the Aurora PostgreSQL cluster"
  default     = "prod-aurora-pg"
}

variable "engine_version" {
  type        = string
  description = "Aurora PostgreSQL engine version"
  default     = "15.4"
}

variable "database_name" {
  type        = string
  description = "Initial default database name to create"
  default     = "appdb"
}

variable "master_username" {
  type        = string
  description = "Master database username"
  default     = "dbadmin"
}

variable "vpc_id" {
  type        = string
  description = "Target VPC ID where database and proxy reside"
  default     = "vpc-0123456789abcdef0"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of VPC private subnet IDs for Multi-AZ deployment"
  default     = ["subnet-0123456789abcdef0", "subnet-0abcdef1234567890", "subnet-0987654321fedcba0"]
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks authorized for database and proxy network access"
  default     = ["10.0.0.0/16"]
}

variable "min_capacity" {
  type        = number
  description = "Minimum Aurora Capacity Units (ACUs) for Serverless v2 scaling"
  default     = 0.5
}

variable "max_capacity" {
  type        = number
  description = "Maximum Aurora Capacity Units (ACUs) for Serverless v2 scaling"
  default     = 16.0
}

variable "instance_count" {
  type        = number
  description = "Number of Aurora Serverless v2 db.serverless cluster instances"
  default     = 2
}

variable "backup_retention_period" {
  type        = number
  description = "Number of days for continuous automated backup retention"
  default     = 14
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection to prevent accidental cluster teardown"
  default     = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Whether to bypass creating a final snapshot on destroy"
  default     = false
}

variable "kms_key_arn" {
  type        = string
  description = "Optional custom KMS Key ARN for storage and Secrets Manager encryption"
  default     = null
}
