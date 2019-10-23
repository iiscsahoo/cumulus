data "archive_file" "async_operation" {
  type = "zip"
  source_dir = "${path.module}/../../lambdas/asyncOperations/"
  output_path = "${path.module}/../../lambdas/asyncOperations/lambda.zip"
}

resource "aws_lambda_function" "async_operation_fail" {
  function_name    = "${var.prefix}-AsyncOperationFail"
  filename         = "${path.module}/../../lambdas/asyncOperations/lambda.zip"
  source_code_hash = "${data.archive_file.async_operation.output_base64sha256}"
  handler          = "index.fail"
  role             = module.cumulus.lambda_processing_role_arn
  runtime          = "nodejs8.10"

  tags = local.default_tags

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.no_ingress_all_egress.id]
  }
}
resource "aws_lambda_function" "async_operation_success" {
  function_name    = "${var.prefix}-AsyncOperationSuccess"
  filename         = "${path.module}/../../lambdas/asyncOperations/lambda.zip"
  source_code_hash = "${data.archive_file.async_operation.output_base64sha256}"
  handler          = "index.success"
  role             = module.cumulus.lambda_processing_role_arn
  runtime          = "nodejs8.10"

  tags = local.default_tags

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.no_ingress_all_egress.id]
  }
}

data "archive_file" "sns_s3_test" {
  type = "zip"
  source_dir = "${path.module}/../../lambdas/snsS3Test/"
  output_path = "${path.module}/../../lambdas/snsS3Test/lambda.zip"
}

resource "aws_lambda_function" "sns_s3_test" {
  function_name    = "${var.prefix}-SnsS3Test"
  filename         = "${path.module}/../../lambdas/snsS3Test/lambda.zip"
  source_code_hash = "${data.archive_file.sns_s3_test.output_base64sha256}"
  handler          = "index.handler"
  role             = module.cumulus.lambda_processing_role_arn
  runtime          = "nodejs8.10"

  environment {
    variables = {
      system_bucket = var.system_bucket
      stackName     = var.prefix
    }
  }

  tags = local.default_tags

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.no_ingress_all_egress.id]
  }
}
