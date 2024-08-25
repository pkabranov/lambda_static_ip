import json
import requests


def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "ip_address ": requests.get('https://api.ipify.org').text
        })
    }
