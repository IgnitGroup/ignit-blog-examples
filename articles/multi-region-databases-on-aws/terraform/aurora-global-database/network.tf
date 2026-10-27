data "aws_availability_zones" "primary" {
  provider = aws.primary
  state    = "available"
}

data "aws_availability_zones" "secondary" {
  provider = aws.secondary
  state    = "available"
}

resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block           = var.primary_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.name_prefix}-primary" }
}

resource "aws_vpc" "secondary" {
  provider             = aws.secondary
  cidr_block           = var.secondary_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.name_prefix}-secondary" }
}

resource "aws_subnet" "primary_database" {
  count = 2

  provider          = aws.primary
  vpc_id            = aws_vpc.primary.id
  availability_zone = data.aws_availability_zones.primary.names[count.index]
  cidr_block        = cidrsubnet(var.primary_vpc_cidr, 8, count.index)

  tags = { Name = "${var.name_prefix}-primary-db-${count.index + 1}" }
}

resource "aws_subnet" "secondary_database" {
  count = 2

  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary.id
  availability_zone = data.aws_availability_zones.secondary.names[count.index]
  cidr_block        = cidrsubnet(var.secondary_vpc_cidr, 8, count.index)

  tags = { Name = "${var.name_prefix}-secondary-db-${count.index + 1}" }
}

resource "aws_route_table" "primary_database" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  tags = { Name = "${var.name_prefix}-primary-db" }
}

resource "aws_route_table" "secondary_database" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  tags = { Name = "${var.name_prefix}-secondary-db" }
}

resource "aws_route_table_association" "primary_database" {
  count = 2

  provider       = aws.primary
  route_table_id = aws_route_table.primary_database.id
  subnet_id      = aws_subnet.primary_database[count.index].id
}

resource "aws_route_table_association" "secondary_database" {
  count = 2

  provider       = aws.secondary
  route_table_id = aws_route_table.secondary_database.id
  subnet_id      = aws_subnet.secondary_database[count.index].id
}

resource "aws_db_subnet_group" "primary" {
  provider   = aws.primary
  name       = "${var.name_prefix}-primary"
  subnet_ids = aws_subnet.primary_database[*].id

  tags = { Name = "${var.name_prefix}-primary" }
}

resource "aws_db_subnet_group" "secondary" {
  provider   = aws.secondary
  name       = "${var.name_prefix}-secondary"
  subnet_ids = aws_subnet.secondary_database[*].id

  tags = { Name = "${var.name_prefix}-secondary" }
}

resource "aws_security_group" "primary_database" {
  provider    = aws.primary
  name_prefix = "${var.name_prefix}-db-"
  description = "Access to the primary Aurora cluster"
  vpc_id      = aws_vpc.primary.id

  tags = { Name = "${var.name_prefix}-primary-db" }
}

resource "aws_security_group" "secondary_database" {
  provider    = aws.secondary
  name_prefix = "${var.name_prefix}-db-"
  description = "Access to the secondary Aurora cluster"
  vpc_id      = aws_vpc.secondary.id

  tags = { Name = "${var.name_prefix}-secondary-db" }
}

resource "aws_vpc_security_group_ingress_rule" "primary_database" {
  for_each = toset(var.primary_ingress_cidrs)

  provider          = aws.primary
  security_group_id = aws_security_group.primary_database.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.database_port
  to_port           = var.database_port
}

resource "aws_vpc_security_group_ingress_rule" "secondary_database" {
  for_each = toset(var.secondary_ingress_cidrs)

  provider          = aws.secondary
  security_group_id = aws_security_group.secondary_database.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.database_port
  to_port           = var.database_port
}

resource "aws_vpc_security_group_egress_rule" "primary_database" {
  provider          = aws.primary
  security_group_id = aws_security_group.primary_database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "secondary_database" {
  provider          = aws.secondary
  security_group_id = aws_security_group.secondary_database.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
