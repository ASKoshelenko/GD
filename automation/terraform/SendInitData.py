import boto3, os
from boto3.dynamodb.conditions import Key, Attr
import logging

#Create own looger and set log display level 
logger = logging.getLogger()                        
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    sns = boto3.client('sns') 
    
    response = table.scan(
        FilterExpression=Attr('subscription').eq('active')
    )
    items = response['Items']
    scenario_id = os.environ['ScenarioName']
    with table.batch_writer() as batch:
        for item in items:
            if "scenarios" in item:
                if "access_key" in item["scenarios"][scenario_id]:
                    logger.info(f"sending email to {item['email']}")
                    sns.publish(
                        TopicArn = item['topic_arn'],
                        Message =  'Here is your data for the scenario: \nname =  %s\naccess_key = %s\nsecret_key = %s ' % (item["scenarios"][scenario_id]["name"], item["scenarios"][scenario_id]["access_key"], item["scenarios"][scenario_id]["secret_key"]) 
                    )
                    del item["scenarios"][scenario_id]["secret_key"]
                    del item["scenarios"][scenario_id]["access_key"]
        batch.put_item(Item=item)