terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

module "state_backend" {
  source = "../../"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  project     = var.project
  environment = var.environment
  region      = var.region
  dr_region   = var.dr_region

  noncurrent_version_expiration_days = 30
  flow_logs_enabled                  = true

  replication_account_id = var.replication_account_id

  tags = {
    Owner       = "platform-team"
    Compliance  = "sox"
    Environment = var.environment
  }
}
