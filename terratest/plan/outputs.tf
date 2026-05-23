output "bucket_name" {
  value = module.state_backend.bucket_name
}

output "bucket_arn" {
  value = module.state_backend.bucket_arn
}

output "lock_table_name" {
  value = module.state_backend.lock_table_name
}

output "kms_key_arn" {
  value = module.state_backend.kms_key_arn
}

output "kms_key_alias" {
  value = module.state_backend.kms_key_alias
}

output "dr_bucket_name" {
  value = module.state_backend.dr_bucket_name
}

output "region" {
  value = module.state_backend.region
}
