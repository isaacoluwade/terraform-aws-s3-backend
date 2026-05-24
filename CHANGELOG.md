# Changelog

All notable changes to this module are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/), versioning follows
[SemVer](https://semver.org/).

## [2.0.0] - 2026-05-24

### Breaking changes

- **Region short-code derivation rewritten** (S-1 fix). The `region_code`
  local previously derived its value from a substring formula that produced
  non-canonical codes (`us-east-1` → `useast1`, `eu-west-2` → `euwest2`,
  `ap-southeast-1` → `apsoutheast1`). v2.0.0 replaces it with an explicit
  `region_code_map` lookup, giving the canonical short codes
  (`use1`, `euw2`, `apse1`, ...). **Every resource name and every `Name`
  tag in this module shifts as a result.** Consumers upgrading from
  v1.x will see destroy+recreate on first apply.

  See [`UPGRADE_GUIDE.md`](../UPGRADE_GUIDE.md) at the workspace root for
  the recommended per-environment cutover sequence.

## [1.0.0] - 2026-05-22

### Added

- Initial release of `terraform-aws-s3-backend`.
- Primary S3 bucket with versioning, public access blocking, SSE-KMS encryption
  with bucket keys enabled, ownership-enforced ACL disablement, and a
  configurable non-current version expiration (default 90 days).
- DynamoDB state lock table with on-demand billing, point-in-time recovery,
  and KMS encryption.
- Customer-managed KMS key with annual rotation and a 30-day deletion window.
- Optional cross-region replication: when `dr_region` is set, the module
  provisions a replica bucket in the DR region, a multi-region KMS key with
  a replica in DR, a DynamoDB global-table replica, and a replication
  configuration with delete-marker replication enabled.
- Optional flow-logs companion bucket via `flow_logs_enabled`.
- Support for cross-account replication via `replication_account_id`.
- Native `terraform test` suite covering defaults, naming, and validation
  (~30 assertions, all running against `mock_provider "aws" {}`).
- Terratest suite covering happy-path apply and DR replication round-trip.
- `examples/main/` minimal consumer and `examples/complete/` full-featured
  consumer.

### Module contract

- Required inputs: `project`, `environment`, `region`.
- Optional inputs: `dr_region`, `tags`, `noncurrent_version_expiration_days`,
  `flow_logs_enabled`, `replication_account_id`.
- Outputs: `bucket_name`, `bucket_arn`, `lock_table_name`, `kms_key_arn`,
  `kms_key_alias`, `region`, `dr_bucket_name`.

[1.0.0]: https://github.com/example/terraform-aws-s3-backend/releases/tag/v1.0.0
