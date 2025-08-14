locals {
  lmbs = { for lmb in var.lambdas : lmb.name => lmb }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role_example"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy_example"
  description = "Minimal permissions for Parameter Store, DynamoDB, and VPC networking"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Read-only Parameter Store access
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      },
      # Full access to the DynamoDB table
      {
        Effect = "Allow"
        Action = "dynamodb:*"
        Resource = [
          "arn:aws:dynamodb:eu-central-1:253490768279:table/lambda-table"
        ]
      },
      # CloudWatch Logs permissions
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # EC2 permissions for Lambda in a VPC
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Python Lambda Function
resource "aws_lambda_function" "python_lambda" {
  for_each = local.lmbs

  function_name    = each.value.name
  role             = aws_iam_role.lambda_role.arn
  handler          = each.value.handler
  runtime          = each.value.runtime
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  memory_size      = 128
  timeout          = 900
  vpc_config {
    subnet_ids         = [for k in each.value.subnets : var.subnets[k]]
    security_group_ids = [for k in each.value.security_groups : var.sg_ids_by_name[k]]
  }
}

# Package the Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/python/lambda_function.py"
  output_path = "${path.root}/python/lambda_function.zip"
}
