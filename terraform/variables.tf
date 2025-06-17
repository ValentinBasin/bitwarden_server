variable "hcloud_token" {
  sensitive = true
  type      = string
}

variable "cloudflare_api_token" {
  sensitive = true
  type      = string
}

variable "server_type" {
  type    = string
  default = "cx22"
}

variable "image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "datacenter" {
  type    = string
  default = "fsn1-dc14"
}

variable "zone_id" {
  type = string
}

variable "server_name" {
  type    = string
  default = "bitwarden"
}

variable "aws_region" {
  type = string
}

variable "backup_bucket_name" {
  type = string
}

variable "telegram_bot_token" {
  type      = string
  sensitive = true
}

variable "telegram_chat_id" {
  type      = string
  sensitive = true
}

variable "s3_bucket_prefix" {
  type    = string
  default = ""
}

variable "check_schedule_cron" {
  type    = string
  default = "cron(0 3 * * ? *)"
}

variable "monitor_function_name_prefix" {
  type    = string
  default = "s3-backup-monitor"
}

variable "telegram_gateway_function_name_prefix" {
  type    = string
  default = "sns-to-telegram-gateway"
}

variable "sns_topic_name" {
  type    = string
  default = "S3-Backup-Alerts"
}
