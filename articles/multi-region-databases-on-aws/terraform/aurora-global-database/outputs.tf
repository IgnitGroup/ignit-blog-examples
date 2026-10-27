output "global_cluster_identifier" {
  description = "Aurora Global Database identifier."
  value       = aws_rds_global_cluster.this.id
}

output "primary_writer_endpoint" {
  description = "Writer endpoint in the primary Region."
  value       = aws_rds_cluster.primary.endpoint
}

output "primary_reader_endpoint" {
  description = "Reader endpoint in the primary Region."
  value       = aws_rds_cluster.primary.reader_endpoint
}

output "secondary_reader_endpoint" {
  description = "Reader endpoint in the secondary Region. Null when headless replication is enabled."
  value       = var.create_secondary_instance ? aws_rds_cluster.secondary.reader_endpoint : null
}

output "primary_vpc_id" {
  value = aws_vpc.primary.id
}

output "secondary_vpc_id" {
  value = aws_vpc.secondary.id
}
