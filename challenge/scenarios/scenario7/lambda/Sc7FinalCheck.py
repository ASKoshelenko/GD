import json
import boto3
import os
import logging
from datetime import datetime, timedelta
from botocore.config import Config

# Create own logger and set log display level
logs = logging.getLogger()
logs.setLevel(logging.INFO)

STEPS = ['ListRoles', 'AssumeRole']
FINAL_EVENT = 'ListBuckets'
CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS = 7


def lambda_handler(event, context):
    scenario_id = os.environ['ScenarioName']
    users = []

    # Get users for scenario
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    # Connect to cloudtrail by boto3
    trail = boto3.client('cloudtrail')

    # Get table items
    userids = table.scan(
        ProjectionExpression='userid'
    )['Items']

    # Read emails and get usernames
    for userid in userids:
        item = table.get_item(
            Key={"userid": userid['userid']},
            ProjectionExpression='\
            scenarios.#scenario.passed,\
            scenarios.#scenario.username,\
            scenarios.#scenario.events,\
            email,\
            username,\
            userid',
            ExpressionAttributeNames={
                '#scenario': scenario_id
            }
        )['Item']
        if not item['scenarios'][scenario_id]['passed']:
            user = {}
            try:
                user['userid'] = item['userid']
                user['username'] = item['username']
                user['usernameid'] = item['scenarios'][scenario_id]['username']
                user['passed'] = item['scenarios'][scenario_id]['passed']
            except KeyError:
                logs.exception(f"KeyError in user['userid']")
                continue
            user['email'] = item['email']
            try:
                user['events'] = item['scenarios'][scenario_id]['events']
            except KeyError:
                logs.exception(
                    f"KeyError  item['scenarios'][scenario_id]['events']"
                    f" ===== {item['scenarios'][scenario_id]['events']}")
                user['events'] = []
            users.append(user)
    for user in users:
        # Collection for all event names
        event_list = get_trail_events(user['usernameid'], user['events'])
        event_name_list = get_events_names(event_list)
        # Check completion
        if FINAL_EVENT in event_name_list:
            print("works")
            user['cheat'] = False
            # Check steps existing at log
            for step in STEPS:
                if step not in event_name_list:
                    user['cheat'] = True
            # Send congratulation email
            send_email(user['email'], user['userid'])
            total_time = count_total_time(event_list)
            print(f"total_time was: {total_time}")
            # Update user at db events
            update = table.update_item(
                Key={
                    'userid': user['userid']
                },
                UpdateExpression="set \
                    scenarios.#scenario.#passed = :r, \
                    scenarios.#scenario.#cheat = :c, \
                    scenarios.#scenario.#total_time = :t, \
                    scenarios.#scenario.#events = :l",
                ExpressionAttributeNames={
                    "#scenario": scenario_id,
                    "#passed": "passed",
                    "#cheat": "cheat",
                    "#total_time": "total_time",
                    "#events": "events"
                },
                ExpressionAttributeValues={
                    ':r': True,
                    ':c': user['cheat'],
                    ':t': total_time,
                    ':l': event_list
                },
                ReturnValues="UPDATED_NEW"
            )
            logs.info(update)
        else:
            # Update user at db events
            update = table.update_item(
                Key={
                    'userid': user['userid']
                },
                UpdateExpression="set scenarios.#scenario.#events = :l",
                ExpressionAttributeNames={
                    "#scenario": scenario_id,
                    "#events": "events"
                },
                ExpressionAttributeValues={
                    ':l': event_list
                },
                ReturnValues="UPDATED_NEW"
            )
            logs.info(update)


def get_trail_events(username, user_events):
    regions = ["eu-central-1", "us-east-1"]
    # Connect to cloudtrail by boto3
    all_trail = []
    # Create return map
    # user = {}
    # user['events'] = user_events
    user = {'events': user_events}
    for region in regions:
        my_config = Config(region_name=region)
        # Connect to cloudtrail by boto3
        trail = boto3.client('cloudtrail', config=my_config)

        # Create return map
        # user = {}
        # user['events'] = user_events
        user = {'events': user_events}

        current_date_str, days_ago_str = get_date_range()

        # Collect and process all events by instance profile
        events = trail.lookup_events(
            LookupAttributes=[
                {
                    'AttributeKey': 'Username',
                    'AttributeValue': username
                }
            ],
            StartTime=days_ago_str,
            EndTime=current_date_str,
            MaxResults=50
        )

        # Reset list for all event names
        event_list = []

        # Get all user events without error
        for event in events['Events']:
            try:
                json.loads(event['CloudTrailEvent'])['errorCode']
            except KeyError:
                event_list.append({
                    "name": event['EventName'],
                    "time": event['EventTime'].strftime(
                        "%d-%b-%Y (%H:%M:%S.%f)")
                })
                event = json.loads(event['CloudTrailEvent'])

        # Get only unique events for db and trail
        if user['events'] == {}:
            user['events'] = []
        user['events'] = event_list + user['events']
        all_trail += (user["events"])
    all_trail = unique_events(all_trail)
    return all_trail


def get_events_names(event_list):
    events = []
    for event in event_list:
        events.append(event['name'])
    logs.info(events)
    return events


# Get only unique events
def unique_events(event_list):
    events = []
    for event in event_list:
        if event not in events:
            events.append(event)
    return events


def sort_events(events):
    return events['time']


def count_total_time(events):
    events.sort(key=sort_events)
    start = datetime.strptime(events[0]['time'],
                                       '%d-%b-%Y (%H:%M:%S.%f)')
    durations = []
    end = datetime.now()
    duration = end - start
    durations.append(
        {
            'start': start.strftime("%d-%b-%Y (%H:%M:%S.%f)"),
            'end': end.strftime("%d-%b-%Y (%H:%M:%S.%f)"),
            'duration': str(duration)
        })
    logs.info(f" Durations: {durations}")
    return durations


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


def get_date_range():
    # Get current date
    current_date = datetime.now()

    # Get StartTime
    days_ago_date = current_date - timedelta(
        days=CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS)

    current_date_str = current_date.isoformat()
    days_ago_str = days_ago_date.isoformat()
    return current_date_str, days_ago_str
