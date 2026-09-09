data "aws_caller_identity" "current" {}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  ephi_bucket_name  = "${var.project_name}-ephi-${local.account_id}"
  trail_bucket_name = "${var.project_name}-cloudtrail-${local.account_id}"
  kms_alias         = "alias/${var.project_name}-ephi"
  operator_user     = try(element(split("/", data.aws_caller_identity.current.arn), 1), null)
  is_iam_user       = can(regex("^arn:aws:iam::", data.aws_caller_identity.current.arn))
}

module "ephi_kms" {
  source = "../../modules/kms"

  project_name = var.project_name
  alias_name   = local.kms_alias
}

module "ephi_bucket" {
  source = "../../modules/s3-data-bucket"

  project_name              = var.project_name
  bucket_name               = local.ephi_bucket_name
  kms_key_arn               = module.ephi_kms.key_arn
  allowed_upload_principals = [data.aws_caller_identity.current.arn]
}

module "audit_trail" {
  source = "../../modules/cloudtrail"

  project_name           = var.project_name
  trail_name             = "${var.project_name}-trail"
  s3_bucket_name         = local.trail_bucket_name
  kms_key_arn            = module.ephi_kms.key_arn
  data_event_bucket_arns = [module.ephi_bucket.bucket_arn]
}

data "aws_iam_policy_document" "ephi_operator" {
  statement {
    sid    = "ListAndReadWriteEphiBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
    ]
    resources = [
      module.ephi_bucket.bucket_arn,
      "${module.ephi_bucket.bucket_arn}/*",
    ]
  }

  statement {
    sid    = "UseEphiKmsKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [module.ephi_kms.key_arn]
  }
}

resource "aws_iam_policy" "ephi_operator" {
  name        = "${var.project_name}-ephi-operator"
  description = "Least-privilege access to upload and read synthetic ePHI in the Phase 2 bucket."
  policy      = data.aws_iam_policy_document.ephi_operator.json
}

resource "aws_iam_user_policy_attachment" "ephi_operator" {
  count = var.attach_operator_policy_to_current_user && local.is_iam_user ? 1 : 0

  user       = local.operator_user
  policy_arn = aws_iam_policy.ephi_operator.arn
}
