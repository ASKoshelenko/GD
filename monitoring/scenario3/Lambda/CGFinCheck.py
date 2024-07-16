import re, boto3, json, os
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
    
    # Get scenario name from environment
    scenario_id = os.environ['ScenarioName']
    
    # Get users for scenario
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    
    # Connect to cloudtrail by boto3
    trail = boto3.client('cloudtrail')
    
    # Get table items
    items = table.scan()['Items']
    
    # Read emails and get usernames
    for item in items:
        if item['scenarios'][scenario_id]['passed'] == False :
            user={}
            user['username'] = item['scenarios'][scenario_id]['username']
            user['email'] = item['email']
            user['events'] = item['scenarios'][scenario_id]['user_events']
            user['topic_arn'] = item['topic_arn']
            users.append(user)

    # Collect and process all events without error by user
    for user in users :
        # Collection for all event names
        eventList = []

        events = trail.lookup_events(
        LookupAttributes=[
            {
                'AttributeKey': 'Username',
                'AttributeValue': user['username']
            },
        ])['Events']
        
        # Get all events
        for event in events :
            try :
                json.loads(event['CloudTrailEvent'])['errorCode']
            except KeyError:
                eventList.append(event['EventName'])

        # Get only unique events for db and trail
        if user['events'] == {} : user['events']=[]
        user['events'] = list(set((eventList + user['events'])))
        
        # Check completion
        if FINAL_EVENT in user['events'] :
            logger.info("works")
            # Check is user a cheater 
            try:
                
                # Check steps existing at log
                for step in STEPS:
                    if eventList.index(step) >= 0:
                        user['cheat'] = False
                    
            except ValueError:
                user['cheat'] = True
            
            # Send congratulation email
            send_message(user['topic_arn'], user['cheat'])
            
            # Update user at db user_events
            update = table.update_item(
            Key={
                    'email': user['email']
                },
                UpdateExpression="set scenarios.scenario1.#passed = :r, scenarios.scenario1.#cheat = :c, scenarios.scenario1.#ev = :l",
                ExpressionAttributeNames = {
                "#passed" : "passed",
                "#cheat" : "cheat",
                "#ev" : "user_events"
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
            # Update user at db user_events
            update = table.update_item(
                Key={
                    'email': user['email']
                },
                UpdateExpression="set scenarios.scenario1.#ev = :l",
                ExpressionAttributeNames = {
                    "#ev" : "user_events"
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
        