output "bucket_name" {
  description = "Echo of the module's bucket_name output."
  value       = module.state_backend.bucket_name
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
