import os
import time
import json
import ssl
import boto3
import urllib.request
import urllib.error
from datetime import datetime
from botocore.exceptions import BotoCoreError, ClientError

# DynamoDB client
dynamodb = boto3.resource("dynamodb")

# Config
MONITOR_URL = os.environ.get("MONITOR_URL", "https://b47f85463dd9.ngrok-free.app")
TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "lambda-table")
CHECK_INTERVAL = 5  # seconds
TIMEOUT = 30  # seconds

# Optional SSL verification
VERIFY_SSL = os.environ.get("VERIFY_SSL", "true").lower() == "true"

def check_endpoint(url):
    """Perform an HTTP GET and return status code or error."""
    start_time = time.time()
    status_code = None
    error_message = None

    try:
        if not VERIFY_SSL:
            ctx = ssl._create_unverified_context()
        else:
            ctx = ssl.create_default_context()

        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as response:
            status_code = response.getcode()

    except urllib.error.HTTPError as e:
        status_code = e.code
        error_message = str(e)
    except urllib.error.URLError as e:
        error_message = str(e.reason)
    except ssl.SSLError as e:
        error_message = f"SSL error: {e}"
    except ValueError:
        error_message = f"Invalid URL: {url}"
    except Exception as e:
        error_message = f"Unexpected error: {e}"

    return status_code, error_message


def lambda_handler(event, context):
    table = dynamodb.Table(TABLE_NAME)
    start_time = time.time()

    while (time.time() - start_time) < context.get_remaining_time_in_millis() / 1000:
        timestamp = datetime.utcnow().isoformat() + "Z"
        status_code, error_message = check_endpoint(MONITOR_URL)

        item = {
            "timestamp": timestamp,
            "status_code": status_code if status_code is not None else -1,
            "error": error_message if error_message else ""
        }

        # Write to DynamoDB
        try:
            table.put_item(Item=item)
        except (BotoCoreError, ClientError) as e:
            print(f"[ERROR] Failed to write to DynamoDB: {e}")

        # Log to CloudWatch
        print(json.dumps(item))

        time.sleep(CHECK_INTERVAL)

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Monitoring finished for this invocation"})
    }
