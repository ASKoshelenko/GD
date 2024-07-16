import boto3
import os
import re
import json
import time
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime
import logging

# Create own logger and set log display level
logger = logging.getLogger()
logger.setLevel(logging.INFO)

send_regex = re.compile(r'^(secret|access|username|target).*$')

lambda_client = boto3.client('lambda')

scenario_id = os.environ['ScenarioName']

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')


def lambda_handler(event, context):
    # Get table items
    users = table.scan(
        ProjectionExpression='userid'
    )['Items']
    # Read userIds and get scenario
    # logger.info(f"Emails will be processed for the {os.environ.get("ScenarioName", None)} scenario")
    for user in users:
        item = table.get_item(
            Key={"userid": user['userid']},
            ProjectionExpression='scenarios.#scenario, \
                email, \
                username, \
                userid',
            ExpressionAttributeNames={
                '#scenario': scenario_id
            }
        )['Item']
        logger.info('working on %s', item['userid'])
        logger.info('Found something like secret/access key')
        try:
            placeholders = {}
            placeholders['ScenarioName'] = scenario_id
            placeholders['name'] = item['username']
            placeholders['userid'] = item['userid']
            for key, value in item["scenarios"][scenario_id].items():
                if send_regex.search(key):
                    placeholders[key] = value
            logger.info('Sending email')
            print(item['username'])
            lambda_client.invoke(
                FunctionName='SendingNotifications',
                InvocationType='Event',
                Payload=json.dumps({
                    'template_name': scenario_id,
                    'email': item['email'],
                    'userid': item['userid'],
                    'placeholders': placeholders
                })
            )
        except KeyError:
            logger.exception("Keys not Exists")
        time.sleep(10)