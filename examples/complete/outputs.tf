output "bucket_name" {
  description = "Name of the primary state bucket."
  value       = module.state_backend.bucket_name
}

output "dr_bucket_name" {
  description = "Name of the DR replica bucket."
  value       = module.state_backend.dr_bucket_name
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key."
  value       = module.state_backend.kms_key_arn
}

output "backend_config" {
  description = "Snippet you can paste into another module's backend block."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${module.state_backend.bucket_name}"
        key            = "<replace-me>/terraform.tfstate"
        region         = "${module.state_backend.region}"
        dynamodb_table = "${module.state_backend.lock_table_name}"
        kms_key_id     = "${module.state_backend.kms_key_arn}"
        encrypt        = true
      }
    }
  EOT
}
