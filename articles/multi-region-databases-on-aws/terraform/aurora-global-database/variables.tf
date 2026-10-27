variable "name_prefix" {
  description = "Prefix used for resource names. Use lowercase letters, numbers and hyphens."
  type        = string
  default     = "aurora-global-demo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,39}$", var.name_prefix))
    error_message = "name_prefix must start with a lowercase letter and contain 3-40 lowercase letters, numbers or hyphens."
  }
}

variable "primary_region" {
  description = "AWS Region containing the writer cluster."
  type        = string
  default     = "eu-west-1"
}

variable "secondary_region" {
  description = "AWS Region containing the read-only secondary cluster."
  type        = string
  default     = "eu-central-1"
}

variable "primary_vpc_cidr" {
  description = "CIDR block for the primary VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "secondary_vpc_cidr" {
  description = "CIDR block for the secondary VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "primary_ingress_cidrs" {
  description = "Trusted IPv4 CIDRs allowed to connect to PostgreSQL in the primary VPC. Empty by default."
  type        = list(string)
  default     = []
}

variable "secondary_ingress_cidrs" {
  description = "Trusted IPv4 CIDRs allowed to connect to PostgreSQL in the secondary VPC. Empty by default."
  type        = list(string)
  default     = []
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "applicationdb"
}

variable "database_username" {
  description = "Master database username."
  type        = string
  default     = "dbadmin"
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
  description = "Aurora PostgreSQL major or minor version available in both Regions."
  type        = string
  default     = "16.6"
}

variable "database_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}

variable "primary_min_acu" {
  description = "Minimum Aurora capacity units for the primary Serverless v2 cluster. AWS recommends at least 8 ACUs for Aurora Global Database writers."
  type        = number
  default     = 8
}

variable "primary_max_acu" {
  description = "Maximum Aurora capacity units for the primary Serverless v2 cluster."
  type        = number
  default     = 16
}

variable "secondary_min_acu" {
  description = "Minimum Aurora capacity units for the secondary Serverless v2 cluster."
  type        = number
  default     = 0.5
}

variable "secondary_max_acu" {
  description = "Maximum Aurora capacity units for the secondary Serverless v2 cluster."
  type        = number
  default     = 4
}

variable "create_secondary_instance" {
  description = "Create a reader instance in the secondary cluster. Set false for headless replication; add capacity before promotion."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Protect global and regional clusters from accidental deletion. Enable for long-lived environments."
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
