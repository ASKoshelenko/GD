import re
import boto3
import json
import logging

#Create own looger and set log display level 
logger = logging.getLogger()                        
logger.setLevel(logging.INFO)

# define steps event names
STEPS = ['ListAttachedUserPolicies', 'ListPolicyVersions', 'GetPolicyVersion']

# get all SetDefaultPolicyVersion event from cloudtrail
FINAL_EVENT = 'SetDefaultPolicyVersion'

def lambda_handler(event, context):
    # Clollection for all users 
    users=[]
    
    # Collection for all event names
    eventList = []
    
    # Get users for scenario
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    
    # Connect to cloudtrail by boto3
    trail = boto3.client('cloudtrail')
    
    # Get table items
    items = table.scan()['Items']
    
    # Read emails and get usernames
    for item in items:
        if item['Scenarios'][0]['passed'] == False :
            match = re.search('.*@', item['email'])[0]
            user={}
            user['name'] = match[:-1]
            user['email'] = item['email']
            user['events'] = item['Scenarios'][0]['CTevents']
            user['arn'] = item['topic_arn']
            users.append(user)

    # Collect and process all events without error by user
    for user in users :
        events = trail.lookup_events(
        LookupAttributes=[
            {
                'AttributeKey': 'Username',
                'AttributeValue': user['name']
            },
        ])
        
        # Get all events
        for event in events['Events']:
            if event['detail']['requestParameters'] != None :
                eventList.append(event['EventName'])

        # Get only unique events for db and trail
        if user['events'] == {} : user['events']=[]
        user['events'] = list(set((eventList + user['events'])))
        
        # Check completion
        if user['events'].count(FINAL_EVENT) !=0:
            logger.info("Works")
            # Check is user a cheater 
            try:                
                # Check steps existing at log
                for step in STEPS:
                    if eventList.index(step) >= 0:
                        user['cheat'] = False
                    
            except ValueError:
                user['cheat'] = True
            
            # Send congratulation email
            send_message(user['arn'], user['cheat'])
            
            # Update user at db CTevents
            update = table.update_item(
            Key={
                    'email': user['email']
                },
                UpdateExpression="set Scenarios[0].#passed = :r, Scenarios[0].#cheat = :c, Scenarios[0].#ev = :l",
                ExpressionAttributeNames = {
                "#passed" : "passed",
                "#cheat" : "cheat",
                "#ev" : "CTevents"
                },
                ExpressionAttributeValues={
                    ':r': True,
                    ':c': user['cheat'],
                    ':l': user['events']
                },
                ReturnValues="UPDATED_NEW"
            )
            logger.info(update)
        else :
            # Update user at db CTevents
            update = table.update_item(
                Key={
                    'email': user['email']
                },
                UpdateExpression="set Scenarios[0].#ev = :l",
                ExpressionAttributeNames = {
                    "#ev" : "CTevents"
                },
                ExpressionAttributeValues = {
                    ':l' : user['events'] 
                },
                ReturnValues="UPDATED_NEW"
            )
            logger.info(update)


# Send congrats message        
def send_message(topicArn, cheat):
    sns = boto3.client('sns')
    if not cheat :
        cheater = False
        sns.publish(
            TopicArn = topicArn,
            Message = 'Congratulations, you are successfully comlepted first scenario of EPAM AWS security challenge'  
        )
    else :
        cheater = True
        sns.publish(
            TopicArn = topicArn,
            Message = 'Congratulations, you are successfully comlepted first scenario of EPAM AWS security challenge, but you are cheater!!!'  
        )
        