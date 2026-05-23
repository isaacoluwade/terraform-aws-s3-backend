locals {
  region_code = format(
    "%s%s",
    substr(replace(var.region, "-", ""), 0, length(replace(var.region, "-", "")) - 1),
    substr(var.region, length(var.region) - 1, 1),
  )

  primary_name = "${var.project}-${var.environment}-${local.region_code}"

  module_version = trimspace(file("${path.module}/VERSION"))

  default_tags = {
    Project       = var.project
    Environment   = var.environment
    Region        = var.region
    ManagedBy     = "terraform"
    Module        = "terraform-aws-s3-backend"
    ModuleVersion = local.module_version
  }

  tags = merge(var.tags, local.default_tags)

  replication_enabled = var.dr_region != null
  caller_account_id   = data.aws_caller_identity.current.account_id
  replication_account = coalesce(var.replication_account_id, local.caller_account_id)
}

data "aws_caller_identity" "current" {}

# --------------------------------------------------------------------------
# Primary bucket
# --------------------------------------------------------------------------

resource "aws_s3_bucket" "state" {
  bucket = "${local.primary_name}-state"
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    # Required by the AWS provider: every rule needs a filter.
    # Empty filter = applies to all objects.
    filter {}
  }
}

# --------------------------------------------------------------------------
# KMS key (multi-region when DR is enabled)
# --------------------------------------------------------------------------

resource "aws_kms_key" "state" {
  description             = "${local.primary_name} Terraform state backend KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  multi_region            = local.replication_enabled

  policy = data.aws_iam_policy_document.kms_key.json

  tags = local.tags
}

resource "aws_kms_alias" "state" {
  name          = "alias/${local.primary_name}-state"
  target_key_id = aws_kms_key.state.key_id
}

# --------------------------------------------------------------------------
# DynamoDB lock table (global table when DR is enabled)
# --------------------------------------------------------------------------

resource "aws_dynamodb_table" "lock" {
  name         = "${local.primary_name}-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.state.arn
  }

  dynamic "replica" {
    for_each = local.replication_enabled ? toset([var.dr_region]) : toset([])

    content {
      region_name            = replica.value
      kms_key_arn            = aws_kms_replica_key.state[0].arn
      point_in_time_recovery = true
    }
  }

  tags = local.tags
}

# --------------------------------------------------------------------------
# Replication infrastructure (DR mode only)
# --------------------------------------------------------------------------

resource "aws_s3_bucket" "state_replica" {
  count = local.replication_enabled ? 1 : 0

  provider = aws.dr
  bucket   = "${local.primary_name}-state-replica"
  tags     = local.tags
}

resource "aws_s3_bucket_versioning" "state_replica" {
  count = local.replication_enabled ? 1 : 0

  provider = aws.dr
  bucket   = aws_s3_bucket.state_replica[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state_replica" {
  count = local.replication_enabled ? 1 : 0

  provider = aws.dr
  bucket   = aws_s3_bucket.state_replica[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_replica" {
  count = local.replication_enabled ? 1 : 0

  provider = aws.dr
  bucket   = aws_s3_bucket.state_replica[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_replica_key.state[0].arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state_replica" {
  count = local.replication_enabled ? 1 : 0

  provider = aws.dr
  bucket   = aws_s3_bucket.state_replica[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_kms_replica_key" "state" {
  count = local.replication_enabled ? 1 : 0

  provider                = aws.dr
  description             = "${local.primary_name} state replica key"
  primary_key_arn         = aws_kms_key.state.arn
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.kms_replica_key[0].json
  tags                    = local.tags
}

resource "aws_kms_alias" "state_replica" {
  count = local.replication_enabled ? 1 : 0

  provider      = aws.dr
  name          = "alias/${local.primary_name}-state"
  target_key_id = aws_kms_replica_key.state[0].key_id
}

resource "aws_iam_role" "replication" {
  count = local.replication_enabled ? 1 : 0

  name               = "${local.primary_name}-state-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_assume_role[0].json
  tags               = local.tags
}

resource "aws_iam_role_policy" "replication" {
  count = local.replication_enabled ? 1 : 0

  name   = "${local.primary_name}-state-replication"
  role   = aws_iam_role.replication[0].id
  policy = data.aws_iam_policy_document.replication_permissions[0].json
}

resource "aws_s3_bucket_replication_configuration" "state" {
  count = local.replication_enabled ? 1 : 0

  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.state.id

  # Replication configuration depends on versioning being enabled on both ends.
  depends_on = [
    aws_s3_bucket_versioning.state,
    aws_s3_bucket_versioning.state_replica,
  ]

  rule {
    id       = "primary-to-dr"
    status   = "Enabled"
    priority = 1

    filter {}

    destination {
      bucket        = aws_s3_bucket.state_replica[0].arn
      storage_class = "STANDARD"
      account       = local.replication_account

      encryption_configuration {
        replica_kms_key_id = aws_kms_replica_key.state[0].arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}

# --------------------------------------------------------------------------
# Flow-logs companion bucket (optional)
# --------------------------------------------------------------------------

resource "aws_s3_bucket" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = "${local.primary_name}-flow-logs"
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  count = var.flow_logs_enabled ? 1 : 0

  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    id     = "expire-flow-logs"
    status = "Enabled"

    expiration {
      days = 90
    }

    filter {}
  }
}
