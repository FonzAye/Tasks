# health_check.py
import requests

def lambda_handler(event, context):
    url = 'https://32b2c93fff1e.ngrok-free.app/'
    
    try:
        response = requests.get(url, timeout=5)
        status_code = response.status_code
        response_time = response.elapsed.total_seconds()
        
        if 200 <= status_code <= 399:
            message = f'Status code: {status_code}, Response time: {response_time:.2f}s'
        elif 400 <= status_code <= 599:
            message = f'We are in trouble Houston! Status code: {status_code}'
        else:
            message = f'Unexpected status code: {status_code}'
            
        print(message)
        return {"statusCode": status_code, "message": message}

    except requests.exceptions.RequestException as e:
        error_message = f'Request failed: {e}'
        print(error_message)
        return {"statusCode": 500, "message": error_message}
