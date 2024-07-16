import boto3, os, re
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime
import logging

#Create own looger and set log display level 
logger = logging.getLogger()                        
logger.setLevel(logging.INFO)

send_regex = re.compile(r'^(secret|access|username|target).*$')

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
                logger.info(f"working on {item['email']}")
                for key in list(item["scenarios"][scenario_id]):
                    if not "notified_at" in item["scenarios"][scenario_id]:
                        logger.info('Found something like secret/access key')                
                        try :
                            emailMessage = \
                            'Here is your data for the scenario:\r\n\r\n'
                            for key, value in item["scenarios"][scenario_id].items():
                                if send_regex.search(key):
                                    emailMessage = emailMessage + \
                                    '%s = %s\r\n' % (key, value)
                            emailMessage = emailMessage + \
                            '\r\n' + item["scenarios"][scenario_id]["description"]
                        except KeyError : 
                            logger.exception("Keys not Exists")
                            emailMessage = item["scenarios"][scenario_id]["description"]
                        logger.info('Sending email')
                        sns.publish(
                            TopicArn = item['topic_arn'],
                            Message = emailMessage                
                        )
                        item["scenarios"][scenario_id]["notified_at"] = str(datetime.utcnow())
                        batch.put_item(Item=item)
                        break