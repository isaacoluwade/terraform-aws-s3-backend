mock_provider "aws" {}
mock_provider "aws" {
  alias = "dr"
}

run "rejects_project_too_short" {
  command = plan

  variables {
    project     = "ab"
    environment = "test"
    region      = "us-east-1"
  }

  expect_failures = [
    var.project,
  ]
}

run "rejects_project_too_long" {
  command = plan

  variables {
    project     = "this-is-way-too-long"
    environment = "test"
    region      = "us-east-1"
  }

  expect_failures = [
    var.project,
  ]
}

run "rejects_project_with_uppercase" {
  command = plan

  variables {
    project     = "Caas"
    environment = "test"
    region      = "us-east-1"
  }

  expect_failures = [
    var.project,
  ]
}

run "rejects_environment_with_uppercase" {
  command = plan

  variables {
    project     = "test"
    environment = "Prod"
    region      = "us-east-1"
  }

  expect_failures = [
    var.environment,
  ]
}

run "rejects_invalid_region" {
  command = plan

  variables {
    project     = "test"
    environment = "test"
    region      = "not-a-region"
  }

  expect_failures = [
    var.region,
  ]
}

run "rejects_invalid_dr_region" {
  command = plan

  variables {
    project     = "test"
    environment = "test"
    region      = "us-east-1"
    dr_region   = "nonsense"
  }

  expect_failures = [
    var.dr_region,
  ]
}

run "rejects_dr_region_equal_to_region" {
  command = plan

  variables {
    project     = "test"
    environment = "test"
    region      = "us-east-1"
    dr_region   = "us-east-1"
  }

  expect_failures = [
    var.dr_region,
  ]
}

run "rejects_excessive_noncurrent_version_expiration" {
  command = plan

  variables {
    project                            = "test"
    environment                        = "test"
    region                             = "us-east-1"
    noncurrent_version_expiration_days = 9999
  }

  expect_failures = [
    var.noncurrent_version_expiration_days,
  ]
}

run "rejects_short_noncurrent_version_expiration" {
  command = plan

  variables {
    project                            = "test"
    environment                        = "test"
    region                             = "us-east-1"
    noncurrent_version_expiration_days = 3
  }

  expect_failures = [
    var.noncurrent_version_expiration_days,
  ]
}

run "rejects_malformed_replication_account_id" {
  command = plan

  variables {
    project                = "test"
    environment            = "test"
    region                 = "us-east-1"
    dr_region              = "us-west-2"
    replication_account_id = "not-numeric"
  }

  expect_failures = [
    var.replication_account_id,
  ]
}
