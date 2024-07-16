from datetime import datetime
import boto3
import os
from boto3.dynamodb.conditions import Key, Attr
import logging

# Create own logger and set log display level
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    sns = boto3.client('sns')
    scenario_id = os.environ['ScenarioName']

    # Takes away the date from the script completion date and sends messages to
    # those who didn't make it 24 hours before the script completion.
    for item in table.scan()['Items']:
        if not item['scenarios'][scenario_id]['passed']:
            if (datetime.strptime(
                    item['scenarios'][scenario_id]['destroy_date'],
                    "%Y-%m-%dT%H:%M:%SZ") - datetime.utcnow()).days <= 1:
                logger.warning("Alert sent to %s", item['email'])
                sns.publish(
                    TopicArn=item['topic_arn'],
                    Message='You have 24 hours to complete the scenario, after'
                            ' that time it will be destroyed.'
                )
