variable "project" {
  type        = string
  description = "Project / platform name. Drives primary_name and the Project tag on every resource. Lowercase letters, digits, and hyphens only; 3-12 characters."

  validation {
    condition     = can(regex("^[a-z0-9-]{3,12}$", var.project))
    error_message = "project must be 3-12 chars, lowercase letters, digits, and hyphens only."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod, ci-*). Drives primary_name and the Environment tag. Lowercase letters, digits, and hyphens only."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "environment must be lowercase letters, digits, and hyphens only."
  }
}

variable "region" {
  type        = string
  description = "Primary AWS region (e.g. us-east-1). Where the state bucket and lock table live."

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.region))
    error_message = "region must look like 'us-east-1', 'eu-west-2', etc."
  }
}

variable "dr_region" {
  type        = string
  description = "DR region for cross-region replication (e.g. us-west-2). When set, the module provisions a replica bucket, KMS replica key, and replication configuration. When null, no DR resources are created."
  default     = null

  validation {
    condition     = var.dr_region == null || can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.dr_region))
    error_message = "dr_region must be null or a valid AWS region."
  }

  validation {
    condition     = var.dr_region == null || var.dr_region != var.region
    error_message = "dr_region must differ from region."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to merge with the module's default tag spine. Keys that conflict with the spine are overridden by the spine."
  default     = {}
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Days to retain non-current versions of state files before deletion. Set to a value that survives your longest plausible 'oh no, we need to roll back state' window."
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days >= 7 && var.noncurrent_version_expiration_days <= 730
    error_message = "noncurrent_version_expiration_days must be between 7 and 730 (two years)."
  }
}

variable "flow_logs_enabled" {
  type        = bool
  description = "When true, also creates a flow-logs destination bucket and lifecycle policy. Off by default; only set true when this state backend will also host VPC flow logs for the platform."
  default     = false
}

variable "replication_account_id" {
  type        = string
  description = "Account ID hosting the DR bucket, when different from the caller account. Defaults to the caller account, i.e. same-account replication."
  default     = null

  validation {
    condition     = var.replication_account_id == null || can(regex("^[0-9]{12}$", var.replication_account_id))
    error_message = "replication_account_id must be null or a 12-digit AWS account ID."
  }
}
