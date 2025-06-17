output "aws_access_key" {
  value     = aws_iam_access_key.bitwarden_user_key.id
  sensitive = true
}

output "aws_secret_key" {
  value     = aws_iam_access_key.bitwarden_user_key.secret
  sensitive = true
}

output "sns_topic_arn" {
  description = "The ARN of the SNS Topic for backup alerts."
  value       = aws_sns_topic.backup_alerts_topic.arn
}

output "s3_monitor_lambda_name" {
  description = "The name of the S3 Monitor Lambda function."
  value       = aws_lambda_function.s3_monitor_lambda.function_name
}

output "telegram_gateway_lambda_name" {
  description = "The name of the SNS to Telegram Gateway Lambda function."
  value       = aws_lambda_function.sns_to_telegram_gateway_lambda.function_name
}
