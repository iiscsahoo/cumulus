module "sync_granule_task" {
  source = "../cumulus_lambda_function"

  prefix        = var.prefix
  system_bucket = var.system_bucket
  task_version  = var.task_version

  function_name = "SyncGranule"
  filename = "${path.module}/../../tasks/sync-granule/dist/lambda.zip"

  handler               = "index.handler"
  role                  = var.lambda_processing_role_arn
  runtime               = "nodejs8.10"
  timeout               = 300
  memory_size           = 1024
  environment_variables = {
    CMR_ENVIRONMENT             = var.cmr_environment
    stackName                   = var.prefix
    system_bucket               = var.system_bucket
    CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
  }
  subnet_ids            = var.lambda_subnet_ids
  security_group_ids    = var.lambda_subnet_ids == null ? null : [aws_security_group.no_ingress_all_egress[0].id]

  layers = [var.cumulus_message_adapter_lambda_layer_arn]

  enable_versioning = var.enable_task_versioning

  tags = merge(local.default_tags, { Project = var.prefix })
}

resource "aws_cloudwatch_log_group" "sync_granule_task" {
  name = "/aws/lambda/${module.sync_granule_task.lambda_function_name}"
  retention_in_days = 30
  tags = local.default_tags
}

resource "aws_cloudwatch_log_subscription_filter" "sync_granule_task" {
  name            = "${var.prefix}-SyncGranuleSubscription"
  destination_arn = var.log2elasticsearch_lambda_function_arn
  filter_pattern  = ""
  log_group_name  = aws_cloudwatch_log_group.sync_granule_task.name
  distribution    = "ByLogStream"
}