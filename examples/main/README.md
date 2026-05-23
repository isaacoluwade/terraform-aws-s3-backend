# `examples/main` — minimal S3 backend

Provisions a single-region Terraform state backend with no DR.

## Apply

```bash
terraform init
terraform apply
```

Outputs `backend_config` — paste into another module's backend block.

## Tear down

```bash
terraform destroy
```
