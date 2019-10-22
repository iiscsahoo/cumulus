locals {
  dist_path = "${path.module}/../../tasks/queue-pdrs/dist/lambda.zip"
}

module "queue_pdrs_source" {
  source = "../github_lambda_source"
  archive = local.dist_path
  release = var.release
  repo = "nasa/cumulus"
  zip_file = "cumulus-queue-pdrs-task.zip"
  local_core_lambda = var.local_core_lambda
}


resource "aws_lambda_function" "queue_pdrs_task" {
  depends_on       = [ queue_pdrs_source ]
  function_name    = "${var.prefix}-QueuePdrs"
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
      CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = var.lambda_subnet_ids == null ? null : [aws_security_group.no_ingress_all_egress[0].id]
  }

  tags = merge(local.default_tags, { Project = var.prefix })
}

resource "aws_cloudwatch_log_group" "queue_pdrs_task" {
  name              = "/aws/lambda/${aws_lambda_function.queue_pdrs_task.function_name}"
  retention_in_days = 30
  tags              = local.default_tags
}

resource "aws_cloudwatch_log_subscription_filter" "queue_pdrs_task" {
  name            = "${var.prefix}-QueuePdrsLogSubscription"
  destination_arn = var.log2elasticsearch_lambda_function_arn
  log_group_name  = aws_cloudwatch_log_group.queue_pdrs_task.name
  filter_pattern  = ""
  distribution    = "ByLogStream"
}
