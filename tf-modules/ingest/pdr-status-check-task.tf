locals {
  pdr_status_check_dist_path = "${path.module}/../../tasks/pdr-status-check/dist/lambda.zip"
}

module "pdr_status_check_source" {
  source = "../github_lambda_source"
  archive = local.pdr_status_check_dist_path
  release = var.release
   repo = "Jkovarik/cumulus"
  zip_file = "cumulus-discover-pdrs-task.zip"
  local_core_lambda = var.local_core_lambda
}



resource "aws_lambda_function" "pdr_status_check_task" {
  depends_on       = [ module.pdr_status_check_source ]
  function_name    = "${var.prefix}-PdrStatusCheck"
  filename         = local.pdr_status_check_dist_path
  source_code_hash = filebase64sha256(local.pdr_status_check_dist_path)
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
