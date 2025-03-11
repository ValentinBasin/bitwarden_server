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
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 60
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

output "aws_access_key" {
  value     = aws_iam_access_key.bitwarden_user_key.id
  sensitive = true
}

output "aws_secret_key" {
  value     = aws_iam_access_key.bitwarden_user_key.secret
  sensitive = true
}
