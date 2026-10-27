provider "aws" {
  alias  = "primary"
  region = var.primary_region

  default_tags {
    tags = merge(var.tags, {
      Example = "rds-mysql-cross-region-read-replica"
    })
  }
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region

  default_tags {
    tags = merge(var.tags, {
      Example = "rds-mysql-cross-region-read-replica"
    })
  }
}
