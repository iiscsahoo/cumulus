locals {
  move_granules_dist_path = "${path.module}/../../tasks/move-granules/dist/lambda.zip"
}

module "move_granules_source" {
  source = "../github_lambda_source"
  archive = local.move_granules_dist_path
  release = var.release
  repo = "nasa/cumulus"
  zip_file = "cumulus-move-granules-task.zip"
  local_core_lambda = var.local_core_lambda
}


resource "aws_lambda_function" "move_granules_task" {
  depends_on       = [ module.move_granules_source ]
  function_name    = "${var.prefix}-MoveGranules"
  filename         = local.move_granules_dist_path
  source_code_hash = filebase64sha256(local.move_granules_dist_path)
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
