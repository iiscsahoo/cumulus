locals {
  dist_path = "${path.module}/../../tasks/sync-granule/dist/lambda.zip"
}

module "sync_granule_source" {
  source = "../../github_lambda_source"
  archive = local.dist_path
  release = var.release
  repo = "nasa/cumulus"
  zip_file = "cumulus-sync-granule-task.zip"
  local_core_lambda = var.local_core_lambda
}

resource "aws_lambda_function" "sync_granule_task" {
  depends_on       = [ sync_granule_source ]
  function_name    = "${var.prefix}-SyncGranule"
  filename         = local.dist_path
  source_code_hash = filebase64sha256(local.dist_path)
  handler          = "index.handler"
  role             = var.lambda_processing_role_arn
  runtime          = "nodejs8.10"
  timeout          = 300
  memory_size      = 1024

  layers = [var.cumulus_message_adapter_lambda_layer_arn]

  environment {
    variables = {
      CMR_ENVIRONMENT             = var.cmr_environment
      stackName                   = var.prefix
      system_bucket               = var.system_bucket
      CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = var.lambda_subnet_ids == null ? null : [aws_security_group.no_ingress_all_egress[0].id]
  }

  tags = merge(local.default_tags, { Project = var.prefix })
}

resource "aws_cloudwatch_log_group" "sync_granule_task" {
  name = "/aws/lambda/${aws_lambda_function.sync_granule_task.function_name}"
  tags = local.default_tags
}

resource "aws_cloudwatch_log_subscription_filter" "sync_granule_task" {
  name            = "${var.prefix}-SyncGranuleSubscription"
  destination_arn = var.log2elasticsearch_lambda_function_arn
  filter_pattern  = ""
  log_group_name  = aws_cloudwatch_log_group.sync_granule_task.name
  distribution    = "ByLogStream"
}
