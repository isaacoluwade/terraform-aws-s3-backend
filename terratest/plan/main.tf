provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "dr"
  region = coalesce(var.dr_region, var.region)
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

  tags = {
    Owner = "ci-terratest"
  }
}
