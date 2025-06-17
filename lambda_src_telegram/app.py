import os
import json
import urllib.request
import urllib.error

TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID")


def send_telegram_message(message):
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        print("ERROR: Telegram bot token or chat ID is not set.")
        return

    telegram_api_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"

    payload = {"chat_id": TELEGRAM_CHAT_ID, "text": message, "parse_mode": "html"}

    data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        url=telegram_api_url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as response:
            response_body = response.read().decode("utf-8")
            print(f"Telegram API response status: {response.status}")
            print(f"Telegram API response body: {response_body}")
            if response.status != 200:
                print(
                    f"WARNING: Telegram API returned non-200 status: {response.status}"
                )

    except urllib.error.HTTPError as e:
        print(f"ERROR: HTTP Error sending message to Telegram: {e.code} - {e.reason}")
        print(f"Request data: {data}")
        print(f"Response body: {e.read().decode('utf-8')}")
    except urllib.error.URLError as e:
        print(f"ERROR: URL Error sending message to Telegram: {e.reason}")
    except Exception as e:
        print(f"ERROR: Unexpected error sending message to Telegram: {e}")


def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    try:
        message_text = event["Records"][0]["Sns"]["Message"]
        send_telegram_message(message_text)

    except Exception as e:
        error_msg = f"ERROR processing SNS message for Telegram: {e}"
        print(error_msg)
        send_telegram_message(f"🚨 Internal Error: {error_msg} 🚨")

    return {"statusCode": 200, "body": "Message processed."}
