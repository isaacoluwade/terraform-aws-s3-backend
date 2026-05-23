mock_provider "aws" {}
mock_provider "aws" {
  alias = "dr"
}

variables {
  project     = "test"
  environment = "test"
  region      = "us-east-1"
}

run "bucket_versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "state bucket must have versioning Enabled by default"
  }
}

run "public_access_fully_blocked" {
  command = plan

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.state.block_public_acls,
      aws_s3_bucket_public_access_block.state.block_public_policy,
      aws_s3_bucket_public_access_block.state.ignore_public_acls,
      aws_s3_bucket_public_access_block.state.restrict_public_buckets,
    ])
    error_message = "all four public-access-block attributes must be true by default"
  }
}

run "kms_rotation_enabled" {
  command = plan

  assert {
    condition     = aws_kms_key.state.enable_key_rotation == true
    error_message = "KMS key must have annual rotation enabled"
  }
}

run "kms_deletion_window_30_days" {
  command = plan

  assert {
    condition     = aws_kms_key.state.deletion_window_in_days == 30
    error_message = "KMS key deletion window must be 30 days"
  }
}

run "lock_table_has_pitr" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.lock.point_in_time_recovery[0].enabled == true
    error_message = "lock table must have point-in-time recovery enabled"
  }
}

run "lock_table_billing_pay_per_request" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.lock.billing_mode == "PAY_PER_REQUEST"
    error_message = "lock table must use on-demand billing"
  }
}

run "no_replica_when_dr_region_unset" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket.state_replica) == 0
    error_message = "no replica bucket should exist when dr_region is null"
  }

  assert {
    condition     = length(aws_kms_replica_key.state) == 0
    error_message = "no replica KMS key should exist when dr_region is null"
  }
}

run "lifecycle_default_90_days" {
  command = plan

  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.state.rule[0].noncurrent_version_expiration[0].noncurrent_days == 90
    error_message = "default non-current version expiration should be 90 days"
  }
}

run "no_flow_logs_bucket_by_default" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket.flow_logs) == 0
    error_message = "flow-logs bucket should not be created by default"
  }
}

run "bucket_key_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.state.rule[0].bucket_key_enabled == true
    error_message = "bucket key must be enabled for KMS cost optimization"
  }
}

run "ownership_bucket_owner_enforced" {
  command = plan

  assert {
    condition     = aws_s3_bucket_ownership_controls.state.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "object ownership must be BucketOwnerEnforced (ACLs disabled)"
  }
}
