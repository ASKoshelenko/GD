import json, datetime,time
import boto3, time
from boto3.dynamodb.conditions import Key, Attr


def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    sns = boto3.client('sns')
    scenario_num = 0
    sec_in_day = 86400
    now = int(time.time())
    
    # Takes away the date from the script completion date and sends messages to those who didn't make it 24 hours before the script completion.
    for item in table.scan()['Items']:
        if item['Scenarios'][scenario_num]['passed'] == False:
            if item['Scenarios'][scenario_num]['destroy_date'] - now <= item['Scenarios'][scenario_num]['destroy_date'] - sec_in_day:
                sns.publish(
                    TopicArn = item['topic_arn'],
                    Message = 'You have 24 hours to complete the scenario, after that time it will be destroyed.'  
                )