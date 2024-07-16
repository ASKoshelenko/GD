import re, boto3, json, os
from datetime import datetime, timedelta
import logging

CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS = 7

# Create own logger and set log display level 
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

KEY = ""


# Main handler
def lambda_handler(event, context):
    if len(event.values()) > 1:
        logger.info(
            {
                'Message': 'To many keys, I`m unbreakable!!!',
                'Tip': 'If you wanna complete scenario try to uset the '
                       'correct payload',
                'TheCorrectPayload': '{"Key":"your_secretkey_from_rds"}'
            }
        )
        return {
            'Message': 'To many keys, I`m unbreakable!!!',
            'Tip': 'If you wanna complete scenario try to uset the '
                   'correct payload',
            'TheCorrectPayload': '{"Key":"your_secretkey_from_rds"}'
        }
    elif len(event.values()) == 0:
        logger.info(
            {
                'Message': 'Try to add payload',
                'Tip': 'If you wanna complete scenario, try to use the '
                       'correct payload',
                'TheCorrectPayload': '{"Key":"your_secretkey_from_rds"}'
            }
        )
        return {
            'Message': 'Try to add payload',
            'Tip': 'If you wanna complete scenario, try to use the '
                   'correct payload',
            'TheCorrectPayload': '{"Key":"your_secretkey_from_rds"}'
        }

    for key in event.keys():
        try:
            # Get user from DB
            item = table.scan(
                FilterExpression="scenarios.#scenario.target_key = :k",
                ExpressionAttributeNames={
                    "#scenario": scenario_id
                },
                ExpressionAttributeValues={
                    ":k": event[key]
                },
                ProjectionExpression=' \
                    userid, \
                    scenarios.#scenario.username, \
                    scenarios.#scenario.target_key, \
                    scenarios.#scenario.passed, \
                    scenarios.#scenario.events, \
                    email \
                '
            )['Items'][0]
            user['name'] = item['scenarios'][scenario_id]['username']
            KEY = event[key]
            break
        except IndexError:
            logger.exception(f"User with key {event[key]} not exists")
            return f"User with key {event[key]} not exists"

    # Read user data to map 
    if not item['scenarios'][scenario_id]['passed']:
        logger.info("user exists")
        user['events'] = item['scenarios'][scenario_id]['events']
        user['cheat'] = False
        user['email'] = item['email']
        user['userid'] = item['userid']

        # Get trail events and created instance id
        user['events'] = get_trail_events_by_user(user['name'])

        # Check cheating of user
        if len(sub_finder(user['events'], STEPS)) == 0:
            user['cheat'] = True

        total_time = count_total_time(user['events'])
        # update user at db 
        updated = table.update_item(
            Key={
                'userid': user['userid']
            },
            UpdateExpression="set \
                scenarios.#scenario.#passed = :r, \
                scenarios.#scenario.#cheat = :c, \
                scenarios.#scenario.#uev = :u, \
                scenarios.#scenario.#total_time = :t",
            ExpressionAttributeNames={
                "#scenario": scenario_id,
                "#passed": "passed",
                "#cheat": "cheat",
                "#uev": "events",
                "#total_time": "total_time"
            },
            ExpressionAttributeValues={
                ':r': True,
                ':c': user['cheat'],
                ':u': user['events'],
                ':t': total_time
            },
            ReturnValues="UPDATED_NEW"
        )
        logger.info(
            f"Congratulations the key {KEY} is yours and you "
            f"successfully completed scenario 4")

        # Send congratulation email
        send_email(user['email'], user['userid'])


def get_trail_events_by_user(username):
    # Connect to cloudtrail by boto3
    trail = boto3.client('cloudtrail')

    current_date_str, days_ago_str = get_date_range()

    # Collect and process all events by username
    events = trail.lookup_events(
        LookupAttributes=[
            {
                'AttributeKey': 'Username',
                'AttributeValue': username
            }
        ],
        StartTime=days_ago_str,
        EndTime=current_date_str
    )

    # Reset list for all event names
    event_list = []

    # Get all user events without error
    for event in events['Events']:
        try:
            json.loads(event['CloudTrailEvent'])['errorCode']
        except KeyError:
            event_list.append(event['EventName'])

    return list(set(event_list))


# Send congrats message
def send_email(email, userid):
    lambda_client = boto3.client('lambda')
    lambda_client.invoke(
        FunctionName='SendingNotifications',
        InvocationType='Event',
        Payload=json.dumps({
            'template_name': 'congratulations',
            'email': email,
            'userid': userid,
            'placeholders': {
                'ScenarioName': os.environ['ScenarioName']
            }
        })
    )


def sub_finder(mylist, pattern):
    pattern = set(pattern)
    return [x for x in mylist if x in pattern]


def count_total_time(events):
    events = events[::-1]
    durations = []
    end = datetime.now()
    try:
        start = datetime.strptime(events[0]['time'], '%d-%b-%Y (%H:%M:%S.%f)')
    except Exception as e:
        logger.exception("Error ")
        durations.append(
            {
                'start': "events not found",
                'end': end.strftime("%d-%b-%Y (%H:%M:%S.%f)"),
                'duration': "0"
            })
        return durations
    duration = end - start
    durations.append(
        {
            'start': start.strftime("%d-%b-%Y (%H:%M:%S.%f)"),
            'end': end.strftime("%d-%b-%Y (%H:%M:%S.%f)"),
            'duration': str(duration)
        })

    logger.info(durations)
    return durations


def get_date_range():
    # Get current date
    current_date = datetime.now()

    # Get StartTime
    days_ago_date = current_date - timedelta(
        days=CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS)

    current_date_str = current_date.isoformat()
    days_ago_str = days_ago_date.isoformat()
    return current_date_str, days_ago_str
