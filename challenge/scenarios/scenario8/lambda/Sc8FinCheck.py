import boto3
import json
import os
from datetime import datetime, timedelta
import logging
from botocore.config import Config

# Create own logger and set log display level
logs = logging.getLogger()
logs.setLevel(logging.INFO)

# define steps event names
STEPS = ['AddTagsToResource', 'GetParameter']
# STEPS = []
FINAL_EVENT = 'DeleteTable'
CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS = 7


def lambda_handler(event, context):
    # Collection for all users
    users = []

    # Get scenario name from environment
    scenario_id = os.environ['ScenarioName']

    # Get users for scenario
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

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
            scenarios.#scenario.ecr_repository_name,\
            scenarios.#scenario.targetdb_name,\
            email,\
            username,\
            topic_arn,\
            userid',
            ExpressionAttributeNames={
                '#scenario': scenario_id
            }
        )['Item']
        if not item['scenarios'][scenario_id]['passed']:
            user = {}
            try:
                user['userid'] = item['userid']
                user['usernameid'] = item['scenarios'][scenario_id]['username']
                user['username'] = item['username']
                user['ecr_repository_name'] = item['scenarios'][scenario_id][
                    'ecr_repository_name']
                user['targetdb_name'] = item['scenarios'][scenario_id][
                    'targetdb_name']
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

    # Collect and process all events without error by user
    for user in users:

        # Collection for all event names
        event_listmain = get_trail_envents(user['usernameid'], user['events'])
        event_listdyndb = get_trail_envents_dyndb(user['ecr_repository_name'],
                                                  user['events'],
                                                  user['targetdb_name'])
        event_list = event_listmain + event_listdyndb
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

            # Update user at db events
            update = table.update_item(
                Key={
                    'userid': user['userid']
                },
                UpdateExpression="set \
                    scenarios.#scenario.#passed = :r,\
                    scenarios.#scenario.#cheat = :c, \
                    scenarios.#scenario.#events = :l,\
                    scenarios.#scenario.#total_time = :t",
                ExpressionAttributeNames={
                    "#scenario": scenario_id,
                    "#passed": "passed",
                    "#cheat": "cheat",
                    "#events": "events",
                    "#total_time": "total_time"
                },
                ExpressionAttributeValues={
                    ':r': True,
                    ':c': user['cheat'],
                    ':l': event_list,
                    ':t': total_time
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


def get_trail_envents(usernameid, user_events):
    regions = ["eu-central-1", "us-east-1"]
    # Connect to cloudtrail by boto3
    all_trail = []
    for region in regions:
        my_config = Config(region_name=region)
        trail = boto3.client('cloudtrail', config=my_config)

        # Create return map
        # user = {}
        # user['events'] = user_events
        user = {'events': user_events}

        current_date_str, days_ago_str = get_date_range()

        # Read events by username
        events = trail.lookup_events(
            LookupAttributes=[
                {
                    'AttributeKey': 'Username',
                    'AttributeValue': usernameid
                },
            ],
            StartTime=days_ago_str,
            EndTime=current_date_str,
            MaxResults=50
        )['Events']

        # Reset list for all event names
        event_list = []

        # Get all events without error
        for event in events:
            try:
                json.loads(event['CloudTrailEvent'])['errorCode']
            except KeyError:
                #                logs.exception("KeyError ")
                event_list.append({
                    "name": event['EventName'],
                    "time": event['EventTime'].strftime(
                        "%d-%b-%Y (%H:%M:%S.%f)")
                })

        # Get only unique events for db and trail
        if user['events'] == {}:
            user['events'] = []
        user['events'] = unique_events(event_list + user['events'])
        all_trail.append(user["events"])
    all_trail = all_trail[0] + all_trail[1]
    return all_trail


def get_trail_envents_dyndb(usernameid, user_events, resoursename):
    region = "eu-central-1"
    # Connect to cloudtrail by boto3
    my_config = Config(region_name=region)
    trail = boto3.client('cloudtrail', config=my_config)

    # Create return map
    # user = {}
    # user['events'] = user_events
    user = {'events': user_events}

    current_date_str, days_ago_str = get_date_range()

    # Read events by username
    events = trail.lookup_events(
        LookupAttributes=[
            {
                'AttributeKey': 'Username',
                'AttributeValue': usernameid
            },
        ],
        StartTime=days_ago_str,
        EndTime=current_date_str
    )['Events']
    # Reset list for all event names
    event_list = []

    # Get all events without error
    for event in events:
        try:
            json.loads(event['CloudTrailEvent'])['errorCode']
        except KeyError:
            #                logs.exception("KeyError ")
            if event['EventName'] == 'DeleteTable':
                if json.loads(event['CloudTrailEvent'])['requestParameters'][
                    'tableName'] == resoursename:
                    event_list.append({
                        "name": event['EventName'],
                        "time": event['EventTime'].strftime(
                            "%d-%b-%Y (%H:%M:%S.%f)")
                    })

    # Get only unique events for db and trail
    if user['events'] == {}:
        user['events'] = []
    user['events'] = unique_events(event_list + user['events'])
    return user["events"]


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


# Get event names list (without time)
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
    logs.info(events)
    return events


def count_total_time(events):
    events = events[::-1]
    durations = []
    start = datetime.strptime(events[0]['time'], '%d-%b-%Y (%H:%M:%S.%f)')
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


def get_date_range():
    # Get current date
    current_date = datetime.now()

    # Get StartTime
    days_ago_date = current_date - timedelta(
        days=CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS)

    current_date_str = current_date.isoformat()
    days_ago_str = days_ago_date.isoformat()
    return current_date_str, days_ago_str
