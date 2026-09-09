data "terraform_remote_state" "phase2" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "phase2/terraform.tfstate"
    region = var.primary_region
  }
}

data "aws_caller_identity" "current" {}

locals {
  ephi_bucket_arn = data.terraform_remote_state.phase2.outputs.ephi_bucket_arn
  ephi_bucket_name = data.terraform_remote_state.phase2.outputs.ephi_bucket_name
  kms_key_arn      = data.terraform_remote_state.phase2.outputs.kms_key_arn
  account_id       = data.aws_caller_identity.current.account_id
}

# --- Step 1: IAM role and S3 opt-in (permissions before backup jobs) ---

module "backup_service_role" {
  source = "../../modules/backup-service-role"

  role_name = "${var.project_name}-backup-role"
}

resource "aws_backup_region_settings" "primary" {
  resource_type_opt_in_preference = {
    S3 = true
  }
}

resource "aws_backup_region_settings" "dr" {
  provider = aws.dr

  resource_type_opt_in_preference = {
    S3 = true
  }
}

# --- Step 2: Extend KMS key policy for AWS Backup ---

data "aws_iam_policy_document" "kms_with_backup" {
  statement {
    sid    = "EnableAccountRootAdministration"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowS3ServiceUse"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }

  statement {
    sid    = "AllowCloudTrailUse"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }

  statement {
    sid    = "AllowBackupServiceUse"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_kms_key_policy" "ephi_backup" {
  key_id = local.kms_key_arn
  policy = data.aws_iam_policy_document.kms_with_backup.json
}

# --- Step 3: Backup vaults (primary + DR copy with Vault Lock) ---

module "primary_vault" {
  source = "../../modules/backup-vault"
  providers = {
    aws = aws
  }

  vault_name  = var.primary_vault_name
  kms_key_arn = local.kms_key_arn
}

data "aws_iam_policy_document" "dr_kms" {
  statement {
    sid    = "EnableAccountRootAdministration"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowBackupServiceUse"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_kms_key" "dr_backup" {
  provider = aws.dr

  description             = "DR region KMS key for AWS Backup copy vault (us-west-2)"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.dr_kms.json

  tags = {
    Name = "${var.project_name}-dr-backup-cmk"
  }
}

module "copy_vault" {
  source = "../../modules/backup-vault"
  providers = {
    aws = aws.dr
  }

  vault_name          = var.copy_vault_name
  kms_key_arn         = aws_kms_key.dr_backup.arn
  enable_vault_lock   = true
  min_retention_days  = var.vault_lock_min_retention_days
  max_retention_days  = var.vault_lock_max_retention_days
  changeable_for_days = var.vault_lock_changeable_for_days
}

# --- Step 4: Backup plan, selection, and cross-region copy ---

resource "aws_backup_plan" "ephi" {
  name = "${var.project_name}-ephi-plan"

  rule {
    rule_name         = "daily-s3-backup-with-copy"
    target_vault_name = module.primary_vault.vault_name
    schedule          = var.backup_schedule_cron

    lifecycle {
      delete_after = var.primary_retention_days
    }

    copy_action {
      destination_vault_arn = module.copy_vault.vault_arn

      lifecycle {
        delete_after = var.copy_retention_days
      }
    }
  }

  depends_on = [
    module.backup_service_role,
    aws_kms_key_policy.ephi_backup,
    aws_backup_region_settings.primary,
    aws_backup_region_settings.dr,
  ]
}

resource "aws_backup_selection" "ephi_s3" {
  name         = "${var.project_name}-ephi-s3"
  plan_id      = aws_backup_plan.ephi.id
  iam_role_arn = module.backup_service_role.role_arn

  resources = [
    local.ephi_bucket_arn,
  ]
}
