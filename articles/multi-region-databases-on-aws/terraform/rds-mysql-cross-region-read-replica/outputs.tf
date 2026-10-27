output "primary_endpoint" {
  description = "MySQL source instance endpoint."
  value       = aws_db_instance.primary.address
}

output "replica_endpoint" {
  description = "Cross-Region read replica endpoint."
  value       = aws_db_instance.secondary.address
}

output "primary_instance_arn" {
  value = aws_db_instance.primary.arn
}

output "replica_instance_arn" {
  value = aws_db_instance.secondary.arn
}

output "primary_vpc_id" {
  value = aws_vpc.primary.id
}

output "secondary_vpc_id" {
  value = aws_vpc.secondary.id
}
