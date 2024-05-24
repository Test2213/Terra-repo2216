resource "aws_iam_policy" "s3_lambda_trigger_policy" {
  name        = "s3_lamda_policy"
  description = "Allows getobject access to S3 buckets"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "logs:CreateLogStream"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::*/*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "s3_eventtrigger_lambda_role" {
  name               = "s3_eventtrigger_lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3_lambda_policy_attachment" {
  name       = "s3_lambda_policy_attachment"
  policy_arn = aws_iam_policy.s3_lambda_trigger_policy.arn
  roles      = [aws_iam_role.s3_eventtrigger_lambda_role.name]
}
