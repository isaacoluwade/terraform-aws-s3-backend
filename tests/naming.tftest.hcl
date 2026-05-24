mock_provider "aws" {}
mock_provider "aws" {
  alias = "dr"
}

variables {
  project     = "test"
  environment = "test"
  region      = "us-east-1"
}

run "bucket_name_follows_primary_name" {
  command = plan

  assert {
    condition     = aws_s3_bucket.state.bucket == "test-test-use1-state"
    error_message = "bucket name should be $${project}-$${environment}-$${region_code}-state"
  }
}

run "lock_table_name_follows_primary_name" {
  command = plan

  assert {
    condition     = aws_dynamodb_table.lock.name == "test-test-use1-state-locks"
    error_message = "lock table name should be $${primary_name}-state-locks"
  }
}

run "kms_alias_follows_primary_name" {
  command = plan

  assert {
    condition     = aws_kms_alias.state.name == "alias/test-test-use1-state"
    error_message = "KMS alias should be alias/$${primary_name}-state"
  }
}

run "all_resources_carry_module_tag" {
  command = plan

  assert {
    condition     = aws_s3_bucket.state.tags["Module"] == "terraform-aws-s3-backend"
    error_message = "every resource must carry the Module tag"
  }

  assert {
    condition     = aws_dynamodb_table.lock.tags["Module"] == "terraform-aws-s3-backend"
    error_message = "DynamoDB lock table must carry the Module tag"
  }

  assert {
    condition     = aws_kms_key.state.tags["Module"] == "terraform-aws-s3-backend"
    error_message = "KMS key must carry the Module tag"
  }
}

run "all_resources_carry_project_tag" {
  command = plan

  assert {
    condition     = aws_s3_bucket.state.tags["Project"] == "test"
    error_message = "bucket must carry the Project tag"
  }

  assert {
    condition     = aws_s3_bucket.state.tags["Environment"] == "test"
    error_message = "bucket must carry the Environment tag"
  }

  assert {
    condition     = aws_s3_bucket.state.tags["ManagedBy"] == "terraform"
    error_message = "bucket must carry ManagedBy=terraform tag"
  }
}

run "consumer_tags_do_not_override_spine" {
  command = plan

  variables {
    project     = "test"
    environment = "test"
    region      = "us-east-1"
    tags = {
      Module = "evil-override"
      Owner  = "platform-team"
    }
  }

  assert {
    condition     = aws_s3_bucket.state.tags["Module"] == "terraform-aws-s3-backend"
    error_message = "consumer tags must not override the Module tag from the spine"
  }

  assert {
    condition     = aws_s3_bucket.state.tags["Owner"] == "platform-team"
    error_message = "consumer-provided non-spine tags must be applied"
  }
}

run "region_compression_eu_west_2" {
  command = plan

  variables {
    project     = "test"
    environment = "test"
    region      = "eu-west-2"
  }

  assert {
    condition     = aws_s3_bucket.state.bucket == "test-test-euw2-state"
    error_message = "region compression should strip dashes and keep the trailing digit"
  }
}

run "region_compression_ap_southeast_1" {
  command = plan

  variables {
    project     = "test"
    environment = "test"
    region      = "ap-southeast-1"
  }

  assert {
    condition     = aws_s3_bucket.state.bucket == "test-test-apse1-state"
    error_message = "region compression should preserve the trailing digit"
  }
}
