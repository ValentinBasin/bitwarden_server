provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "backup" {
  bucket = var.backup_bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "backup_rotation" {
  bucket = aws_s3_bucket.backup.id
  rule {
    id = "backup-rotation"

    filter {
      prefix = "backups/"
    }

    transition {
      days          = 5
      storage_class = "GLACIER"
    }

    expiration {
      days = 30
    }

    status = "Enabled"
  }
}

resource "aws_iam_policy" "s3_backup_policy" {
  name        = "S3BackupPolicy"
  description = "Policy for server to upload backups to S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.backup.arn,
          "${aws_s3_bucket.backup.arn}/backups/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user" "bitwarden_backup_user" {
  name = "bitwarden_backup_user"
}

resource "aws_iam_user_policy_attachment" "user_policy_attachment" {
  user       = aws_iam_user.bitwarden_backup_user.name
  policy_arn = aws_iam_policy.s3_backup_policy.arn
}

resource "aws_iam_access_key" "bitwarden_user_key" {
  user = aws_iam_user.bitwarden_backup_user.name
}

resource "aws_sns_topic" "backup_alerts_topic" {
  name = var.sns_topic_name
}

# --- Lambda for monitoring S3 ---
data "archive_file" "monitor_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda_src_monitor"
  output_path = "monitor_lambda_payload.zip"
}

resource "aws_iam_role" "monitor_lambda_role" {
  name = "${var.monitor_function_name_prefix}-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "monitor_lambda_basic_execution" {
  role       = aws_iam_role.monitor_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "monitor_s3_list_policy" {
  name        = "${var.monitor_function_name_prefix}-s3-list-policy"
  description = "Allows S3 monitor Lambda to list objects in the target S3 bucket."
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = ["s3:ListBucket"], Effect = "Allow", Resource = "arn:aws:s3:::${var.backup_bucket_name}" }]
  })
}

resource "aws_iam_role_policy_attachment" "monitor_s3_list_attachment" {
  role       = aws_iam_role.monitor_lambda_role.name
  policy_arn = aws_iam_policy.monitor_s3_list_policy.arn
}

resource "aws_iam_policy" "monitor_sns_publish_policy" {
  name        = "${var.monitor_function_name_prefix}-sns-publish-policy"
  description = "Allows S3 monitor Lambda to publish messages to the SNS topic."
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = ["sns:Publish"], Effect = "Allow", Resource = aws_sns_topic.backup_alerts_topic.arn }]
  })
}

resource "aws_iam_role_policy_attachment" "monitor_sns_publish_attachment" {
  role       = aws_iam_role.monitor_lambda_role.name
  policy_arn = aws_iam_policy.monitor_sns_publish_policy.arn
}

resource "aws_lambda_function" "s3_monitor_lambda" {
  function_name    = var.monitor_function_name_prefix
  handler          = "app.lambda_handler"
  runtime          = "python3.13"
  role             = aws_iam_role.monitor_lambda_role.arn
  timeout          = 60
  memory_size      = 128
  filename         = data.archive_file.monitor_lambda_zip.output_path
  source_code_hash = data.archive_file.monitor_lambda_zip.output_base64sha256

  environment {
    variables = {
      S3_BUCKET_NAME = var.backup_bucket_name
      S3_PREFIX      = var.s3_bucket_prefix
      SNS_TOPIC_ARN  = aws_sns_topic.backup_alerts_topic.arn
    }
  }
}

# --- CloudWatch Event Rule for first Lambda ---
resource "aws_cloudwatch_event_rule" "daily_backup_check_rule" {
  name                = "${var.monitor_function_name_prefix}-check-rule"
  description         = "Daily check for S3 backups."
  schedule_expression = var.check_schedule_cron
}

resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_monitor_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_monitor_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_backup_check_rule.arn
}

resource "aws_cloudwatch_event_target" "monitor_lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_backup_check_rule.name
  target_id = "S3MonitorLambda"
  arn       = aws_lambda_function.s3_monitor_lambda.arn
}

# --- Lambda for sending Telegram ---
data "archive_file" "telegram_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda_src_telegram"
  output_path = "telegram_lambda_payload.zip"
}

resource "aws_iam_role" "telegram_gateway_lambda_role" {
  name = "${var.telegram_gateway_function_name_prefix}-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "telegram_gateway_lambda_basic_execution" {
  role       = aws_iam_role.telegram_gateway_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "sns_to_telegram_gateway_lambda" {
  function_name    = var.telegram_gateway_function_name_prefix
  handler          = "app.lambda_handler"
  runtime          = "python3.13"
  role             = aws_iam_role.telegram_gateway_lambda_role.arn
  timeout          = 60
  memory_size      = 128
  filename         = data.archive_file.telegram_lambda_zip.output_path
  source_code_hash = data.archive_file.telegram_lambda_zip.output_base64sha256

  environment {
    variables = {
      TELEGRAM_BOT_TOKEN = var.telegram_bot_token
      TELEGRAM_CHAT_ID   = var.telegram_chat_id
    }
  }
}

# SNS Subscription (Subscription first Lambda for SNS topic)
resource "aws_sns_topic_subscription" "telegram_lambda_subscription" {
  topic_arn = aws_sns_topic.backup_alerts_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_to_telegram_gateway_lambda.arn
}

# Lambda Permission (Permision SNS for calling Lambda)
resource "aws_lambda_permission" "allow_sns_to_invoke_telegram_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_to_telegram_gateway_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.backup_alerts_topic.arn
}
