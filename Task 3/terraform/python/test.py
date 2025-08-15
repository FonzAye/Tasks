# health_check.py
import requests
import schedule
import time

def fetch_url():
    try:
        response = requests.get('https://b47f85463dd9.ngrok-free.app')
        status_code = response.status_code
        response_time = response.elapsed.total_seconds()
        
        if status_code >= 200 and status_code <= 399:
            print(f'The status code: {status_code}, Response time: {response_time}')
        elif status_code >= 400 and status_code <= 599:
            print(f'We are in trouble Houston! Status code: {status_code}')
        else:
            print(f'Unexpected status code: {status_code}')
            
    except requests.exceptions.RequestException as e:
        print(f'Request failed: {e}')

schedule.every(5).seconds.do(fetch_url)

while True:
    schedule.run_pending()
    time.sleep(1)