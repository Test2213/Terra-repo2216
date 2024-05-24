provider "aws" {
  region     = "us-west-2" # Update with your desired region
  access_key = ""
  secret_key = ""
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name = "s3_access_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:DeleteLogGroup",
          "logs:DeleteLogStream",
          "logs:DeleteMetricFilter"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject" # Include if you want Lambda to also put objects in S3
        ],
        Resource = "arn:aws:s3:::testls31431/*" # Update with your S3 bucket ARN
      }
    ]
  })
}


# Attach S3 access policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}
# Generates an archive from content, a file, or a directory of files.

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/lambda_function_payload.zip"
}

# Lambda function
resource "aws_lambda_function" "s3_trigger_lambda" {
  filename      = "${path.module}/python/lambda_function_payload.zip" # Path to your Lambda function code
  function_name = "s3_trigger_lambda_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function_payload.lambda_handler" # Update with your handler
  runtime       = "python3.12"                             # Update with your runtime

  # Environment variables if needed
  environment {
    variables = {
      ENV_VAR = "value"
    }
  }
}

# EventBridge rule to trigger Lambda function on S3 PutObject event
resource "aws_cloudwatch_event_rule" "s3_put_event_rule" {
  name        = "s3_put_event_rule"
  description = "Trigger Lambda when object is put into S3"
  event_pattern = jsonencode({
    detail_type = ["object created"],
    source      = ["aws.s3"]
    detail = {
      bucket = {
        name = ["testls31431"]


      }
    }
  })
}

# EventBridge target to invoke Lambda function
resource "aws_cloudwatch_event_target" "invoke_lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_put_event_rule.name
  target_id = "invoke_lambda"
  arn       = aws_lambda_function.s3_trigger_lambda.arn
}

