data "terraform_remote_state" "phase2" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "phase2/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id                       = data.aws_caller_identity.current.account_id
  config_bucket_name               = "${var.project_name}-config-${local.account_id}"
  recorder_name                    = "${var.project_name}-config-recorder"
  delivery_channel                 = "${var.project_name}-config-delivery"
  conformance_pack_template_key    = "conformance-packs/${var.conformance_pack_template}.yaml"
  conformance_pack_template_s3_uri = "s3://${aws_s3_bucket.config.id}/${local.conformance_pack_template_key}"
}

# --- Config delivery bucket (configuration snapshots, not ePHI) ---

resource "aws_s3_bucket" "config" {
  bucket = local.config_bucket_name

  tags = {
    Name = local.config_bucket_name
    Role = "aws-config-snapshots"
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "config_bucket" {
  statement {
    sid    = "AWSConfigBucketPermissionsCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.config.arn]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [local.account_id]
    }
  }

  statement {
    sid    = "AWSConfigBucketExistenceCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.config.arn]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [local.account_id]
    }
  }

  statement {
    sid    = "AWSConfigBucketDelivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.config.arn}/AWSLogs/${local.account_id}/Config/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [local.account_id]
    }
  }

  statement {
    sid    = "AWSConfigConformancePackTemplateRead"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.config.arn}/conformance-packs/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_s3_object" "hipaa_conformance_pack_template" {
  bucket = aws_s3_bucket.config.id
  key    = local.conformance_pack_template_key
  source = "${path.module}/templates/${var.conformance_pack_template}.yaml"
  etag   = filemd5("${path.module}/templates/${var.conformance_pack_template}.yaml")

  tags = {
    Name = var.conformance_pack_template
  }
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id
  policy = data.aws_iam_policy_document.config_bucket.json
}

# --- IAM role for configuration recorder ---

data "aws_iam_policy_document" "config_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "config" {
  name               = "${var.project_name}-config-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume.json
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
}

data "aws_iam_policy_document" "config_s3_delivery" {
  statement {
    sid    = "ConfigDeliveryToLabBucket"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetBucketAcl",
    ]
    resources = [
      aws_s3_bucket.config.arn,
      "${aws_s3_bucket.config.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "config_s3_delivery" {
  name   = "${var.project_name}-config-s3-delivery"
  role   = aws_iam_role.config.id
  policy = data.aws_iam_policy_document.config_s3_delivery.json
}

# --- Recorder, delivery channel, conformance pack ---

resource "aws_config_configuration_recorder" "this" {
  name     = local.recorder_name
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = local.delivery_channel
  s3_bucket_name = aws_s3_bucket.config.id

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_config_conformance_pack" "hipaa" {
  name            = var.conformance_pack_name
  template_s3_uri = local.conformance_pack_template_s3_uri

  depends_on = [
    aws_config_configuration_recorder_status.this,
    aws_s3_object.hipaa_conformance_pack_template,
    aws_s3_bucket_policy.config,
  ]
}
