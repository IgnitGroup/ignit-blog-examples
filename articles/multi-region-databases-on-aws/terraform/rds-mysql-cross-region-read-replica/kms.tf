resource "aws_kms_key" "primary" {
  provider                = aws.primary
  description             = "Encryption key for ${var.name_prefix} in ${var.primary_region}"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "primary" {
  provider      = aws.primary
  name          = "alias/${var.name_prefix}-primary"
  target_key_id = aws_kms_key.primary.key_id
}

resource "aws_kms_key" "secondary" {
  provider                = aws.secondary
  description             = "Encryption key for ${var.name_prefix} in ${var.secondary_region}"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "secondary" {
  provider      = aws.secondary
  name          = "alias/${var.name_prefix}-secondary"
  target_key_id = aws_kms_key.secondary.key_id
}
