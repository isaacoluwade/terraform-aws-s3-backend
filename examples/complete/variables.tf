variable "project" {
  type        = string
  description = "Project name passed through to the module."
  default     = "example"
}

variable "environment" {
  type        = string
  description = "Environment name passed through to the module."
  default     = "dev"
}

variable "region" {
  type        = string
  description = "Primary AWS region."
  default     = "us-east-1"
}

variable "dr_region" {
  type        = string
  description = "DR AWS region for cross-region replication."
  default     = "us-west-2"
}

variable "replication_account_id" {
  type        = string
  description = "Optional cross-account DR account ID. Null = same-account replication."
  default     = null
}
