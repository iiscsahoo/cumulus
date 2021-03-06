resource "aws_lambda_function" "python_reference_task" {
  function_name    = "${var.prefix}-PythonReferenceTask"
  filename         = "${path.module}/../lambdas/python-reference-task/dist/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambdas/python-reference-task/dist/lambda.zip")
  handler          = "initial_task.handler"
  role             = module.cumulus.lambda_processing_role_arn
  runtime          = "python3.7"
  timeout          = 300
  memory_size      = 256

  layers = [var.cumulus_message_adapter_lambda_layer_arn]

  environment {
    variables = {
      stackName                   = var.prefix
      CUMULUS_MESSAGE_ADAPTER_DIR = "/opt/"
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) == 0 ? [] : [1]
    content {
      subnet_ids = var.subnet_ids
      security_group_ids = [
        aws_security_group.no_ingress_all_egress.id
      ]
    }
  }

  tags = var.tags
}
