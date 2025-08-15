import os
import requests
import boto3
import socket
from datetime import datetime, timezone
from botocore.exceptions import ClientError
from urllib.parse import urlparse

# DynamoDB config
DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", "EndpointHealth")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(DYNAMODB_TABLE)

# URL to check
URL = os.environ.get("MONITOR_URL", "https://ad13e832c802.ngrok-free.app/")

def get_ip_from_url(url):
    """Resolve IP address from a URL."""
    try:
        hostname = urlparse(url).hostname
        return socket.gethostbyname(hostname)
    except Exception as e:
        return f"Could not resolve IP: {e}"

def update_failure_count(endpoint_url, status_code, healthy):
    """Update DynamoDB failure count for the endpoint."""
    now = datetime.now(timezone.utc).isoformat() + "Z"

    try:
        if healthy:
            # Reset failure count to 0
            table.put_item(
                Item={
                    "endpoint_url": endpoint_url,
                    "failure_count": 0,
                    "last_checked": now,
                    "last_status_code": status_code
                }
            )
        else:
            # Increment failure count atomically
            table.update_item(
                Key={"endpoint_url": endpoint_url},
                UpdateExpression="""
                    SET failure_count = if_not_exists(failure_count, :start) + :inc,
                        last_checked = :now,
                        last_status_code = :status
                """,
                ExpressionAttributeValues={
                    ":inc": 1,
                    ":start": 0,
                    ":now": now,
                    ":status": status_code
                }
            )
    except ClientError as e:
        print(f"[ERROR] DynamoDB update failed: {e}")

def lambda_handler(event, context):
    ip_address = get_ip_from_url(URL)

    try:
        response = requests.get(URL, timeout=5)
        status_code = response.status_code
        response_time = response.elapsed.total_seconds()

        if 200 <= status_code <= 399:
            message = f"Status: {status_code}, Response time: {response_time:.2f}s, IP: {ip_address}"
            update_failure_count(URL, status_code, healthy=True)

        elif 400 <= status_code <= 500:
            message = f"Status: {status_code}, IP: {ip_address}"
            update_failure_count(URL, status_code, healthy=False)

        else:
            message = f"Unexpected status code: {status_code}, IP: {ip_address}"

        print(message)
        return {"statusCode": status_code, "message": message}

    except requests.exceptions.RequestException as e:
        error_message = f"Request failed: {e}, IP: {ip_address}"
        print(error_message)
        update_failure_count(URL, 0, healthy=False)
        return {"statusCode": 500, "message": error_message}
