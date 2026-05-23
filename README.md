# terraform-aws-s3-backend

Provision a production-grade Terraform state backend in AWS: one S3 bucket,
one DynamoDB lock table, one customer-managed KMS key — with optional
cross-region replication and a flow-logs companion bucket.

This is module 1 of 10 in the [AWS MTKP Terraform Module Library](../projects/1-aws-mtkp-terraform-module-library/).

## Usage

```hcl
module "state_backend" {
  source = "git::https://github.com/<org>/terraform-aws-s3-backend.git?ref=v1.0.0"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  project     = "mtkp"
  environment = "prod"
  region      = "us-east-1"
  dr_region   = "us-west-2"

  tags = {
    CostCenter = "1234"
  }
}
```

The module always requires two provider configurations: the default `aws`
provider for the primary region and an `aws.dr` alias for the DR region. When
DR is not enabled (`dr_region = null`), point `aws.dr` at the same region as
the primary — its resources will not be materialized.

## Operational defaults

- Encryption: SSE-KMS with a module-owned customer-managed key. Bucket keys on.
- Versioning: enabled.
- Public access: fully blocked (all four flags true).
- ACLs: disabled (`BucketOwnerEnforced`).
- KMS key: annual rotation, 30-day deletion window, multi-region when DR is on.
- DynamoDB: on-demand billing, PITR enabled, KMS encrypted.
- Lifecycle: non-current versions expire after `noncurrent_version_expiration_days` (default 90).
- Replication (DR mode): delete markers replicated, KMS-encrypted objects replicated.

None of the above is configurable. They are operational invariants — if a
consumer needs a different posture, they are using the wrong module.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `project` | `string` | — | Required. 3-12 chars, lowercase letters/digits/hyphens. Drives `primary_name` and the Project tag. |
| `environment` | `string` | — | Required. Lowercase letters/digits/hyphens. Drives `primary_name` and the Environment tag. |
| `region` | `string` | — | Required. Primary AWS region (e.g. `us-east-1`). |
| `dr_region` | `string` | `null` | When set, enables cross-region replication. |
| `tags` | `map(string)` | `{}` | Consumer-specific tags merged with the module's spine. |
| `noncurrent_version_expiration_days` | `number` | `90` | Days to retain non-current versions before deletion. Range 7-730. |
| `flow_logs_enabled` | `bool` | `false` | Also creates a flow-logs destination bucket. |
| `replication_account_id` | `string` | `null` | Cross-account DR account ID. Defaults to caller account. |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the primary state S3 bucket. |
| `bucket_arn` | ARN of the primary state bucket. |
| `lock_table_name` | Name of the DynamoDB lock table. |
| `kms_key_arn` | ARN of the customer-managed KMS key. |
| `kms_key_alias` | KMS key alias. |
| `region` | Echo of the input region. |
| `dr_bucket_name` | Name of the DR replica bucket (`null` when DR is off). |

## Examples

- [`examples/main`](./examples/main) — single-region minimal usage.
- [`examples/complete`](./examples/complete) — DR enabled, flow logs, cross-account.

## Testing

Three layers per the [testing pyramid](../projects/1-aws-mtkp-terraform-module-library/01-foundations/04-the-testing-pyramid.md):

```bash
# Layer 1 — static analysis (sub-second)
terraform fmt -check -recursive
tflint --config .tflint.hcl
checkov --config-file .checkov.yaml -d .

# Layer 2 — unit tests with mock_provider (<5s)
terraform test

# Layer 3 — integration tests against real AWS (post-merge only)
cd terratest/test && go test -v -timeout 30m ./...
```

## Versioning

See [CHANGELOG.md](./CHANGELOG.md). Tag `v<MAJOR>.<MINOR>.<PATCH>` is the
immutable artifact; the `VERSION` file mirrors the tag and CI enforces
agreement at release.
