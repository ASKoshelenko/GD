import re, boto3, json, os
import logging

#Create own looger and set log display level 
logger = logging.getLogger()                        
logger.setLevel(logging.INFO)

# Define steps event names
STEPS = ['ListFunctions20150331']

# Get users for scenario
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')

# Initialize user dictionary
user = {}

# Get scenario name from environment
scenario_id = os.environ['ScenarioName']

# Main handler
def lambda_handler(event, context):
    item = None
    for key in event.keys():
        try:
            # Get user from DB
            item = table.scan(
                FilterExpression = "scenarios.#scenario.username = :i",
                ExpressionAttributeNames = {
                    "#scenario" :scenario_id
                },
                ExpressionAttributeValues = {
                    ":i" : event[key]
                }
            )['Items'][0]
            user['name'] = event[key]
            break
        except IndexError:
            logger.exception(f"Exception user {event[key]} not exists")
            continue
    if item == None:
        return 1
        
    # Read user data to map 
    if item['scenarios'][scenario_id]['passed'] == False :
        logger.info("user exists")
        user['events'] = item['scenarios'][scenario_id]['events']
        user['arn'] = item['topic_arn']
        user['cheat'] = False
        user['email'] = item['email']
        
        # Get trail events and created instance id
        user['events'] = get_trail_events_by_user(user['name'])

        # Check cheating of user
        if len(subfinder(user['events'], STEPS)) == 0 :
            user['cheat'] = True
            
        # update user at db 
        updated = table.update_item(
            Key={
                'email': user['email']
            },
            UpdateExpression="set scenarios.#scenario.passed = :r, scenarios.#scenario.#cheat = :c, scenarios.#scenario.#uev = :u",
            ExpressionAttributeNames = {
                "#scenario" : scenario_id,
                "#cheat"    : "cheat",
                "#uev"      : "events"
            },
            ExpressionAttributeValues={
                ':r': True,
                ':c': user['cheat'],
                ':u': user['events']
            },
            ReturnValues="UPDATED_NEW"
        )
        logger.info(updated)

        # Send congratulation email
        send_message(user['arn'], user['cheat'])
        return 

def get_trail_events_by_user(username):
    
    # Connect to cloudtrail by boto3
    trail = boto3.client('cloudtrail')

    # Collect and process all events by username
    events = trail.lookup_events(
    LookupAttributes=[
        {
            'AttributeKey': 'Username',
            'AttributeValue': username
        }
    ])
    
    # Reset list for all event names
    eventList = []
    
    # Get all user events without error
    for event in events['Events']:
        try :
            json.loads(event['CloudTrailEvent'])['errorCode']
        except KeyError:
            logger.exception("KeyError")
            eventList.append(event['EventName'])
                    
    return list(set(eventList))


def send_message(topicArn, cheat):
    sns = boto3.client('sns')
    if not cheat :
        cheater = False
        sns.publish(
            TopicArn = topicArn,
            Message = 'Congratulations, you are successfully comlepted scenario #4 of EPAM AWS security challenge'  
        )
        logger.info("msg sent not cheat")
    else :
        cheater = True
        sns.publish(
            TopicArn = topicArn,
            Message = 'Congratulations, you are successfully comlepted scenario #4 of EPAM AWS security challenge, but you are cheater!!!'  
        )
        logger.info("msg sent cheat")
        
def subfinder(mylist, pattern):
    pattern = set(pattern)
    return [x for x in mylist if x in pattern]