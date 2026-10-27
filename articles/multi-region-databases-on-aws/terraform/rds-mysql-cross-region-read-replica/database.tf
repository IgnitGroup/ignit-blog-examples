resource "aws_db_instance" "primary" {
  provider = aws.primary

  identifier                 = "${var.name_prefix}-primary"
  engine                     = "mysql"
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  storage_type               = "gp3"
  storage_encrypted          = true
  kms_key_id                 = aws_kms_key.primary.arn
  db_name                    = var.database_name
  username                   = var.database_username
  password                   = var.database_password
  port                       = var.database_port
  db_subnet_group_name       = aws_db_subnet_group.primary.name
  vpc_security_group_ids     = [aws_security_group.primary_database.id]
  publicly_accessible        = false
  multi_az                   = false
  backup_retention_period    = 7
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  apply_immediately          = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = true
}

resource "aws_db_instance" "secondary" {
  provider = aws.secondary

  identifier                 = "${var.name_prefix}-secondary"
  replicate_source_db        = aws_db_instance.primary.arn
  instance_class             = var.instance_class
  storage_encrypted          = true
  kms_key_id                 = aws_kms_key.secondary.arn
  port                       = var.database_port
  db_subnet_group_name       = aws_db_subnet_group.secondary.name
  vpc_security_group_ids     = [aws_security_group.secondary_database.id]
  publicly_accessible        = false
  backup_retention_period    = 7
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  apply_immediately          = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = true

  lifecycle {
    # Promotion removes the replication source. Keep Terraform from trying to
    # re-create replication after a console, CLI or automation-driven promotion.
    ignore_changes = [replicate_source_db]
  }
}
