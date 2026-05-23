output "bucket_name" {
  description = "Name of the primary state S3 bucket. Use in the consumer's backend \"s3\" { bucket = … } block."
  value       = aws_s3_bucket.state.bucket
}

output "bucket_arn" {
  description = "ARN of the primary state bucket. For consumers writing IAM policies that scope to this bucket."
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB lock table. Use in the consumer's backend \"s3\" { dynamodb_table = … } block."
  value       = aws_dynamodb_table.lock.name
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key. Use in the consumer's backend \"s3\" { kms_key_id = … } block."
  value       = aws_kms_key.state.arn
}

output "kms_key_alias" {
  description = "KMS key alias (e.g. alias/mtkp-prod-use1-state). Some consumers prefer aliases over ARNs."
  value       = aws_kms_alias.state.name
}

output "region" {
  description = "Echo of the input region. Convenient when wiring multiple modules in a composition."
  value       = var.region
}

output "dr_bucket_name" {
  description = "Name of the DR replica bucket, when DR is enabled. Null otherwise."
  value       = local.replication_enabled ? aws_s3_bucket.state_replica[0].bucket : null
}
