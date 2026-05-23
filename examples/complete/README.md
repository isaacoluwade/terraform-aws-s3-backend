# `examples/complete` — full-featured S3 backend

Provisions a state backend with cross-region replication, a flow-logs companion
bucket, a tighter 30-day non-current version retention, and the option to
replicate into a separate AWS account.

## Apply

```bash
terraform init
terraform apply
```

To exercise the cross-account flow, set `replication_account_id`:

```bash
terraform apply -var replication_account_id=123456789012
```

## Tear down

```bash
terraform destroy
```

> Note: cross-region replication can take 30+ seconds to fully apply.
> S3 buckets created in this example must be empty before destroy succeeds.
