data "aws_iam_policy_document" "kms_key" {
  statement {
    sid    = "EnableRootPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.caller_account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = local.replication_enabled ? toset(["replication"]) : toset([])

    content {
      sid    = "AllowReplicationRole"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [aws_iam_role.replication[0].arn]
      }

      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
        "kms:ReEncrypt*",
      ]

      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = local.replication_enabled && var.replication_account_id != null ? toset(["cross-account"]) : toset([])

    content {
      sid    = "AllowReplicationAccount"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${var.replication_account_id}:root"]
      }

      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
      ]

      resources = ["*"]
    }
  }
}

data "aws_iam_policy_document" "kms_replica_key" {
  count = local.replication_enabled ? 1 : 0

  statement {
    sid    = "EnableRootPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.replication_account}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowReplicationRole"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.replication[0].arn]
    }

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
      "kms:ReEncrypt*",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "replication_assume_role" {
  count = local.replication_enabled ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "replication_permissions" {
  count = local.replication_enabled ? 1 : 0

  statement {
    sid    = "AllowSourceBucketRead"
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]
  }

  statement {
    sid    = "AllowDestinationWrite"
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
    ]

    resources = ["${aws_s3_bucket.state_replica[0].arn}/*"]
  }

  statement {
    sid    = "AllowKMS"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]

    resources = [
      aws_kms_key.state.arn,
      aws_kms_replica_key.state[0].arn,
    ]
  }
}
