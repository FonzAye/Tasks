# health_check.py
import os
import json
import requests
import boto3
import socket
from datetime import datetime, timezone
from botocore.exceptions import ClientError
from urllib.parse import urlparse

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('EndpointHealth')

sns = boto3.client('sns')
ssm = boto3.client('ssm')

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "arn:aws:sns:eu-central-1:253490768279:lambda-endpoint-health-alerts")
ENDPOINTS_PARAM = os.environ.get("ENDPOINTS_PARAM", "/monitoring/endpoints")  

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
        
def send_alert(messages):
    """Send combined alert via SNS."""
    if not SNS_TOPIC_ARN:
        print("[WARNING] SNS_TOPIC_ARN not set. Cannot send alert.")
        return
    
    try:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message="\n".join(messages),
            Subject="ALERT: Endpoint Health Check"
        )
        print("[INFO] Combined SNS alert sent successfully.")
    except ClientError as e:
        print(f"[ERROR] Failed to send SNS notification: {e}")

def lambda_handler(event, context):
    # Load endpoints from SSM Parameter Store
    try:
        param = ssm.get_parameter(Name=ENDPOINTS_PARAM)
        endpoints = json.loads(param['Parameter']['Value'])
    except Exception as e:
        error_message = f"[ERROR] Failed to load endpoints from SSM: {e}"
        print(error_message)
        return {"statusCode": 500, "message": error_message}

    alert_messages = []
    results = []

    for url in endpoints:
        ip_address = get_ip_from_url(url)

        try:
            response = requests.get(url, timeout=5)
            status_code = response.status_code
            response_time = response.elapsed.total_seconds()

            if 200 <= status_code <= 399:
                message = f"[OK] {url} - Status: {status_code}, Response time: {response_time:.2f}s, IP: {ip_address}"
                update_failure_count(url, status_code, healthy=True)

            elif 400 <= status_code <= 599:
                update_failure_count(url, status_code, healthy=False)
                db_item = table.get_item(Key={'endpoint_url': url})
                failure_count = db_item['Item'].get('failure_count', 0)

                if failure_count >= 3:
                    message = f"[ALERT] {url} - Status: {status_code}, Failures: {failure_count}, IP: {ip_address}"
                    alert_messages.append(message)
                else:
                    message = f"[WARN] {url} - Status: {status_code}, Failures: {failure_count}, IP: {ip_address}"
            else:
                message = f"[UNKNOWN] {url} - Unexpected status code: {status_code}, IP: {ip_address}"

            print(message)
            results.append(message)

        except requests.exceptions.RequestException as e:
            error_message = f"[ERROR] {url} - Request failed: {e}, IP: {ip_address}"
            print(error_message)
            results.append(error_message)

    # Send one combined alert if any endpoint failed
    if alert_messages:
        send_alert(alert_messages)

    return {"statusCode": 200, "results": results}
