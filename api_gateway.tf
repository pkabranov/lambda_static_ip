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
