data "terraform_remote_state" "phase2" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "phase2/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "phase3" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "phase3/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  ephi_bucket_arn   = data.terraform_remote_state.phase2.outputs.ephi_bucket_arn
  ephi_bucket_name  = data.terraform_remote_state.phase2.outputs.ephi_bucket_name
  primary_vault     = data.terraform_remote_state.phase3.outputs.primary_vault_name
  copy_vault        = data.terraform_remote_state.phase3.outputs.copy_vault_name
  primary_vault_arn = data.terraform_remote_state.phase3.outputs.primary_vault_arn
  copy_vault_arn    = data.terraform_remote_state.phase3.outputs.copy_vault_arn
  rule_params_base = {
    max_age_hours = tostring(var.max_age_hours)
    bucket_arn    = local.ephi_bucket_arn
  }
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

data "aws_iam_policy_document" "rpo_config_lambda" {
  statement {
    sid    = "PutConfigEvaluations"
    effect = "Allow"
    actions = [
      "config:PutEvaluations",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ListRecoveryPointsPrimary"
    effect = "Allow"
    actions = [
      "backup:ListRecoveryPointsByBackupVault",
    ]
    resources = [local.primary_vault_arn]
  }

  statement {
    sid    = "ListRecoveryPointsCopy"
    effect = "Allow"
    actions = [
      "backup:ListRecoveryPointsByBackupVault",
    ]
    resources = [local.copy_vault_arn]
  }

  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${local.account_id}:*"]
  }
}

resource "aws_iam_role" "rpo_config" {
  name               = "${var.project_name}-rpo-config-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "rpo_config" {
  name   = "${var.project_name}-rpo-config"
  role   = aws_iam_role.rpo_config.id
  policy = data.aws_iam_policy_document.rpo_config_lambda.json
}

resource "aws_cloudwatch_log_group" "rpo_config" {
  name              = "/aws/lambda/${var.project_name}-rpo-freshness-config"
  retention_in_days = 14
}

resource "aws_lambda_function" "rpo_freshness" {
  function_name = "${var.project_name}-rpo-freshness-config"
  role          = aws_iam_role.rpo_config.arn
  handler       = "rpo_freshness_config.lambda_handler"
  runtime       = "python3.11"
  timeout       = 120
  memory_size   = 256

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  depends_on = [
    aws_iam_role_policy.rpo_config,
    aws_cloudwatch_log_group.rpo_config,
  ]
}

# Config validates invoke at PutConfigRule time; wildcard avoids chicken-and-egg with rule ARNs.
resource "aws_lambda_permission" "config_invoke" {
  statement_id   = "AllowConfigInvokeRpoRules"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.rpo_freshness.function_name
  principal      = "config.amazonaws.com"
  source_account = local.account_id
  source_arn     = "arn:aws:config:${var.aws_region}:${local.account_id}:config-rule/*"
}

resource "aws_config_config_rule" "primary_rpo" {
  name = var.primary_rpo_rule_name

  input_parameters = jsonencode(merge(local.rule_params_base, {
    vault_name    = local.primary_vault
    backup_region = var.aws_region
  }))

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.rpo_freshness.arn

    source_detail {
      message_type                = "ScheduledNotification"
      maximum_execution_frequency = "Six_Hours"
    }
  }

  depends_on = [aws_lambda_permission.config_invoke]
}

resource "aws_config_config_rule" "copy_rpo" {
  name = var.copy_rpo_rule_name

  input_parameters = jsonencode(merge(local.rule_params_base, {
    vault_name    = local.copy_vault
    backup_region = var.dr_region
  }))

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.rpo_freshness.arn

    source_detail {
      message_type                = "ScheduledNotification"
      maximum_execution_frequency = "Six_Hours"
    }
  }

  depends_on = [aws_lambda_permission.config_invoke]
}
