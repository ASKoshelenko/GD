import json
import boto3
from boto3.dynamodb.conditions import Key, Attr
import logging

#Create own looger and set log display level 
logger = logging.getLogger()                        
logger.setLevel(logging.INFO)


def lambda_delete_sns(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    sns = boto3.client('sns')
    users = table.scan()['Items']
    for user in users :
        logger.info(sns.delete_topic(TopicArn = user['topic_arn']))
        