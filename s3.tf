resource "aws_s3_bucket" "file_uploads" {
  bucket = "sthreebuckettomail"
}

resource "aws_s3_bucket_notification" "bucket_notifications" {
  bucket = aws_s3_bucket.file_uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_notification.arn
    events              = ["s3:ObjectCreated:*"]
  }
}


resource "aws_sns_topic" "file_uploads_topic" {
  name = "file-uploads-notifications"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.file_uploads_topic.arn
  protocol  = "email"
  endpoint  = "sharmina.lina@gmail.com" # Replace with your email
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_sns_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "Policy for Lambda to access S3 and SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.file_uploads.arn,
          "${aws_s3_bucket.file_uploads.arn}/*",
        ]
      },
      {
        Action   = "sns:Publish",
        Effect   = "Allow"
        Resource = aws_sns_topic.file_uploads_topic.arn
      },
      {
        Action   = "logs:CreateLogGroup",
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = "logs:CreateLogStream",
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = "logs:PutLogEvents",
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


resource "aws_lambda_function" "s3_notification" {
  function_name = "s3-notification-handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"

  filename         = "lambda.zip" # Replace with your Lambda ZIP file path
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.file_uploads_topic.arn
    }
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_notification.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.file_uploads.arn
}

output "lambda_arn" {
  value = aws_lambda_function.s3_notification.arn
}
