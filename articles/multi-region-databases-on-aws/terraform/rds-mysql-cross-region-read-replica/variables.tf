variable "name_prefix" {
  description = "Prefix used for resource names. Use lowercase letters, numbers and hyphens."
  type        = string
  default     = "rds-cross-region-demo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,39}$", var.name_prefix))
    error_message = "name_prefix must start with a lowercase letter and contain 3-40 lowercase letters, numbers or hyphens."
  }
}

variable "primary_region" {
  description = "AWS Region containing the source DB instance."
  type        = string
  default     = "eu-west-1"
}

variable "secondary_region" {
  description = "AWS Region containing the cross-Region read replica."
  type        = string
  default     = "eu-central-1"
}

variable "primary_vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "secondary_vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "primary_ingress_cidrs" {
  description = "Trusted IPv4 CIDRs allowed to connect to MySQL in the primary VPC. Empty by default."
  type        = list(string)
  default     = []
}

variable "secondary_ingress_cidrs" {
  description = "Trusted IPv4 CIDRs allowed to connect to MySQL in the secondary VPC. Empty by default."
  type        = list(string)
  default     = []
}

variable "database_name" {
  type    = string
  default = "applicationdb"
}

variable "database_username" {
  type    = string
  default = "dbadmin"
}

variable "database_password" {
  description = "Master database password. Supply it through TF_VAR_database_password; it is stored in Terraform state."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.database_password) >= 8
    error_message = "database_password must contain at least 8 characters."
  }
}

variable "engine_version" {
  description = "MySQL major or minor version available in both Regions."
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "DB instance class used by the source and replica."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Source database storage in GiB."
  type        = number
  default     = 20
}

variable "database_port" {
  type    = number
  default = 3306
}

variable "deletion_protection" {
  description = "Protect source and replica from accidental deletion. Enable for long-lived environments."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to resources in both Regions."
  type        = map(string)
  default = {
    ManagedBy  = "Terraform"
    Repository = "ignit-blog-examples"
  }
}
