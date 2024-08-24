# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      hashicorp-learn = "lambda-api-gateway"
    }
  }

}

# Actual Lambda function based on ECR image
resource "aws_lambda_function" "container_ip" {
  function_name = "containerIpLambda"
  package_type  = "Image"
  image_uri     = "654654184207.dkr.ecr.us-west-1.amazonaws.com/aws-lambda-static-ip-demo-ecr:latest"
  role          = aws_iam_role.lambda_exec.arn
}

# Log group that stores messages from Lambda
resource "aws_cloudwatch_log_group" "container_ip" {
  name = "/aws/lambda/${aws_lambda_function.container_ip.function_name}"

  retention_in_days = 30
}

# IAM role allows Lambda to access resources in my AWS account
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

# Attaches a Managed IAM Policy to an IAM role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



# Define name for gateway and set its protocol to HTTP
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

# Set up application stages (e.g. Test, Staging, Production). This is only a single stage
resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

# Configures API Gateway to use Lambda
resource "aws_apigatewayv2_integration" "container_ip" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.container_ip.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

# maps an HTTP request to a target, in this case your Lambda function
resource "aws_apigatewayv2_route" "container_ip" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /ip_address"
  target    = "integrations/${aws_apigatewayv2_integration.container_ip.id}"
}

# defines a log group to store access logs
resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

# Gives API Gateway permission to invoke your Lambda function.
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.container_ip.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
