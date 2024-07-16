import json
import boto3
import logging
import time
from boto3.dynamodb.conditions import Key, Attr
import re

logger = logging.getLogger()
logger.setLevel(logging.INFO)

send_regex = re.compile(r'^(secret|access|username|target).*$')

lambda_client = boto3.client('lambda')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')

logger.info(f"Sub-resources {table}")


def lambda_handler(event, context):
    """
    {
      "scenario_name": "scenario1",
      "user_ids": [
        "bohdan_syniuk"
      ]
    }
    """
    scenario_id = event['scenario_name']
    logger.info(scenario_id)

    logger.info(event['user_ids'])

    user_ids_json = event['user_ids']

    logger.info(f"EMAILS {user_ids_json}")

    # Read user_id and get scenario
    for userid in user_ids_json:
        try:
            logger.info(f"Element of json User IDs {userid}")
            if '@' in userid:
                raise ValueError("Invalid userid: '@' symbol not allowed")

            item = table.get_item(
                Key={"userid": userid},
                ProjectionExpression=' \
                    userid, \
                    scenarios.#scenario, \
                    email',
                ExpressionAttributeNames={
                    '#scenario': scenario_id
                }
            )['Item']

            logger.info(f"Working on {item['userid']}")
            logger.info('Found something like secret/access key')
            try:
                placeholders = {}
                placeholders['ScenarioName'] = scenario_id
                for key, value in item["scenarios"][scenario_id].items():
                    if send_regex.search(key):
                        placeholders[key] = value
                logger.info('Sending email')
                lambda_client.invoke(
                    FunctionName='SendingNotifications',
                    InvocationType='Event',
                    Payload=json.dumps({
                        'email': item['email'],
                        'is_resend': True,
                        'placeholders': placeholders,
                        'template_name': scenario_id,
                        'userid': item['userid']
                    })
                )
                # Delay for send emails
                time.sleep(2)
            except KeyError:
                logger.exception("Keys not Exists")

        except Exception:
            logger.exception(f"User ID: {userid} - not found")
            continue
