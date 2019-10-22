locals {
  discover_pdrs_dist = "${path.module}/../../tasks/discover-pdrs/dist/lambda.zip"
}

module "discover_pdrs_source" {
  source = "../github_lambda_source"
  archive = local.discover_pdrs_dist
  release = var.release
  repo = "nasa/cumulus"
  zip_file = "cumulus-discover-pdrs-task.zip"
  local_core_lambda = var.local_core_lambda
}

resource "aws_lambda_function" "discover_pdrs_source" {
  depends_on       = [ module.discover_pdrs_source ]
  filename         = local.discover_pdrs_dist
  function_name    = "${var.prefix}-DiscoverPdrs"
  source_code_hash = filebase64sha256(local.discover_pdrs_dist)
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
      CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = var.lambda_subnet_ids == null ? null : [aws_security_group.no_ingress_all_egress[0].id]
  }

  tags = merge(local.default_tags, { Project = var.prefix })
}

resource "aws_cloudwatch_log_group" "discover_pdrs_task" {
  name              = "/aws/lambda/${aws_lambda_function.discover_pdrs_task.function_name}"
  retention_in_days = 30
  tags              = local.default_tags
}

resource "aws_cloudwatch_log_subscription_filter" "discover_pdrs_task" {
  name            = "${var.prefix}-DiscoverPdrsLogSubscription"
  destination_arn = var.log2elasticsearch_lambda_function_arn
  log_group_name  = aws_cloudwatch_log_group.discover_pdrs_task.name
  filter_pattern  = ""
  distribution    = "ByLogStream"
}
