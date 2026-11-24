output "cluster_id" {
  description = "ID of the Aurora PostgreSQL cluster"
  value       = aws_rds_cluster.aurora.id
}

output "cluster_arn" {
  description = "ARN of the Aurora PostgreSQL cluster"
  value       = aws_rds_cluster.aurora.arn
}

output "cluster_endpoint" {
  description = "Primary writer endpoint for the Aurora cluster"
  value       = aws_rds_cluster.aurora.endpoint
}

output "reader_endpoint" {
  description = "Read-only replica load-balanced endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "proxy_id" {
  description = "ID of the RDS Proxy"
  value       = aws_db_proxy.proxy.id
}

output "proxy_arn" {
  description = "ARN of the RDS Proxy"
  value       = aws_db_proxy.proxy.arn
}

output "proxy_endpoint" {
  description = "Connection pooling proxy endpoint for application workloads"
  value       = aws_db_proxy.proxy.endpoint
}

output "master_user_secret_arn" {
  description = "AWS Secrets Manager secret ARN holding the master credentials"
  value       = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
}

output "cluster_security_group_id" {
  description = "ID of the security group attached to the Aurora cluster"
  value       = aws_security_group.cluster.id
}

output "proxy_security_group_id" {
  description = "ID of the security group attached to the RDS Proxy"
  value       = aws_security_group.proxy.id
}
