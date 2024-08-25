# Actual Lambda function based on ECR image
resource "aws_lambda_function" "container_ip" {
  function_name = "containerIpLambda"
  package_type  = "Image"
  image_uri     = "654654184207.dkr.ecr.us-west-1.amazonaws.com/lambda-static-ip-ecr:latest"
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
