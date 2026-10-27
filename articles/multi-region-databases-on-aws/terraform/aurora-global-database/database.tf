resource "aws_rds_global_cluster" "this" {
  provider = aws.primary

  global_cluster_identifier = var.name_prefix
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
  database_name             = var.database_name
  storage_encrypted         = true
  deletion_protection       = var.deletion_protection
  force_destroy             = !var.deletion_protection
}

resource "aws_rds_cluster" "primary" {
  provider = aws.primary

  cluster_identifier        = "${var.name_prefix}-primary"
  global_cluster_identifier = aws_rds_global_cluster.this.id
  engine                    = aws_rds_global_cluster.this.engine
  engine_version            = aws_rds_global_cluster.this.engine_version
  engine_mode               = "provisioned"
  database_name             = var.database_name
  master_username           = var.database_username
  master_password           = var.database_password
  port                      = var.database_port
  db_subnet_group_name      = aws_db_subnet_group.primary.name
  vpc_security_group_ids    = [aws_security_group.primary_database.id]
  storage_encrypted         = true
  kms_key_id                = aws_kms_key.primary.arn
  backup_retention_period   = 7
  copy_tags_to_snapshot     = true
  apply_immediately         = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = true

  serverlessv2_scaling_configuration {
    min_capacity = var.primary_min_acu
    max_capacity = var.primary_max_acu
  }
}

resource "aws_rds_cluster_instance" "primary" {
  provider = aws.primary

  identifier                   = "${var.name_prefix}-primary-0"
  cluster_identifier           = aws_rds_cluster.primary.id
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.primary.engine
  engine_version               = aws_rds_cluster.primary.engine_version
  auto_minor_version_upgrade   = true
  publicly_accessible          = false
  promotion_tier               = 0
  performance_insights_enabled = false
}

resource "aws_rds_cluster" "secondary" {
  provider = aws.secondary

  cluster_identifier        = "${var.name_prefix}-secondary"
  global_cluster_identifier = aws_rds_global_cluster.this.id
  engine                    = aws_rds_global_cluster.this.engine
  engine_version            = aws_rds_global_cluster.this.engine_version
  engine_mode               = "provisioned"
  source_region             = var.primary_region
  port                      = var.database_port
  db_subnet_group_name      = aws_db_subnet_group.secondary.name
  vpc_security_group_ids    = [aws_security_group.secondary_database.id]
  storage_encrypted         = true
  kms_key_id                = aws_kms_key.secondary.arn
  backup_retention_period   = 7
  copy_tags_to_snapshot     = true
  apply_immediately         = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = true

  serverlessv2_scaling_configuration {
    min_capacity = var.secondary_min_acu
    max_capacity = var.secondary_max_acu
  }

  depends_on = [aws_rds_cluster_instance.primary]

  lifecycle {
    ignore_changes = [replication_source_identifier]
  }
}

resource "aws_rds_cluster_instance" "secondary" {
  count = var.create_secondary_instance ? 1 : 0

  provider = aws.secondary

  identifier                   = "${var.name_prefix}-secondary-0"
  cluster_identifier           = aws_rds_cluster.secondary.id
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.secondary.engine
  engine_version               = aws_rds_cluster.secondary.engine_version
  auto_minor_version_upgrade   = true
  publicly_accessible          = false
  promotion_tier               = 1
  performance_insights_enabled = false
}
