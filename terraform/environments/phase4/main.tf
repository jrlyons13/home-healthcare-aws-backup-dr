data "terraform_remote_state" "phase2" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "phase2/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = data.terraform_remote_state.phase2.outputs.ephi_bucket_name
  bucket_arn  = data.terraform_remote_state.phase2.outputs.ephi_bucket_arn
  kms_key_arn = data.terraform_remote_state.phase2.outputs.kms_key_arn
  verify_object_arns = var.verify_prefix != "" ? ["${local.bucket_arn}/${var.verify_prefix}/*"] : ["${local.bucket_arn}/patients/*"]
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_verifier" {
  statement {
    sid    = "ReadSandboxAndManifest"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = concat(
      [local.bucket_arn, "${local.bucket_arn}/${var.manifest_key}"],
      local.verify_object_arns,
    )
  }

  statement {
    sid    = "DecryptWithEphiKms"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = [local.kms_key_arn]
  }

  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
  }
}

resource "aws_iam_role" "lambda_verifier" {
  name               = "${var.project_name}-verify-restore-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "lambda_verifier" {
  name   = "${var.project_name}-verify-restore"
  role   = aws_iam_role.lambda_verifier.id
  policy = data.aws_iam_policy_document.lambda_verifier.json
}

resource "aws_cloudwatch_log_group" "lambda_verifier" {
  name              = "/aws/lambda/${var.project_name}-verify-restore"
  retention_in_days = 14
}

resource "aws_lambda_function" "verify_restore" {
  function_name = "${var.project_name}-verify-restore"
  role          = aws_iam_role.lambda_verifier.arn
  handler       = "verify_restore.handler"
  runtime       = "python3.11"
  timeout       = 120
  memory_size   = 256

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  environment {
    variables = merge(
      {
        BUCKET_NAME  = local.bucket_name
        MANIFEST_KEY = var.manifest_key
      },
      var.verify_prefix != "" ? { SANDBOX_PREFIX = var.verify_prefix } : {},
    )
  }

  depends_on = [
    aws_iam_role_policy.lambda_verifier,
    aws_cloudwatch_log_group.lambda_verifier,
  ]
}

resource "aws_cloudwatch_event_rule" "restore_completed" {
  name        = "${var.project_name}-restore-completed"
  description = "Trigger integrity verification when an S3 restore job completes."

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Restore Job State Change"]
    detail = {
      status       = ["COMPLETED"]
      resourceType = ["S3"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.restore_completed.name
  target_id = "verify-restore"
  arn       = aws_lambda_function.verify_restore.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify_restore.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.restore_completed.arn
}
