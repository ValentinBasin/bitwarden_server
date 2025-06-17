import boto3
import os
from datetime import datetime, timedelta, timezone

bucket_name = os.environ.get("S3_BUCKET_NAME")
prefix = os.environ.get("S3_PREFIX")
sns_topic_arn = os.environ.get("SNS_TOPIC_ARN")


def lambda_handler(event, context):
    if not bucket_name or not sns_topic_arn:
        return {
            "statusCode": 400,
            "body": "Configuration error: S3_BUCKET_NAME or SNS_TOPIC_ARN missing.",
        }

    s3 = boto3.client("s3")
    sns = boto3.client("sns")

    time_threshold = datetime.now(timezone.utc) - timedelta(hours=24)

    latest_backup_time = None

    try:
        response = s3.list_objects_v2(Bucket=bucket_name, Prefix=prefix, MaxKeys=100)

        if "Contents" in response:
            for obj in response["Contents"]:
                if (
                    latest_backup_time is None
                    or obj["LastModified"] > latest_backup_time
                ):
                    latest_backup_time = obj["LastModified"]

        if latest_backup_time is None or latest_backup_time < time_threshold:
            message = (
                f"Warning: New backup not found in S3 bucket '{bucket_name}' "
                f"with prefix '{prefix}' for the last 24 hours. "
                f"Last backup time: {latest_backup_time if latest_backup_time else 'No backups found'}"
            )
            print(message)
            sns.publish(
                TopicArn=sns_topic_arn,
                Subject="AWS S3 Backup Alert: No Recent Backup Found",
                Message=message,
            )
        else:
            print(f"Backup found. Last backup time: {latest_backup_time}")
            sns.publish(
                TopicArn=sns_topic_arn,
                Subject="Backup found",
                Message=(f"Backup found. Last backup time: {latest_backup_time}"),
            )
    except Exception as e:
        error_message = f"Error Checking Bucket: {e}"
        print(error_message)
        sns.publish(
            TopicArn=sns_topic_arn,
            Subject="AWS S3 Backup Alert: Error Checking Bucket",
            Message=error_message,
        )
