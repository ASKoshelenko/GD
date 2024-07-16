import json
import boto3
import os
from datetime import datetime, timedelta
import logging

CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS = 7

# Create own logger and set log display level
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Define steps event names
STEPS = [
    'DescribeInstances',
    'ListRoles',
    'DescribeSecurityGroups',
    'ListInstanceProfiles',
    'DescribeSubnets',
    'AddRoleToInstanceProfile',
    'RemoveRoleFromInstanceProfile',
    'RunInstances'
]
INSTANCE_STEPS = [
    'ListInstanceAssociations',
    'ModifyInstanceAttribute',
    'UpdateInstanceInformation',
    'TerminateInstances'
]
FINALIZE_STEP = 'RunInstances'
FINALIZE_STEP_I = 'TerminateInstances'


def lambda_handler(data, context):
    # Init scenario id variable
    scenario_id = os.environ['ScenarioName']

    try:
        # Get instance id
        created_id = data['detail']['instance-id']
    except KeyError:
        # Print to log
        logger.exception("it was start of instance")
        # Get instance id
        created_id = data['InstanceId']

    # init user collection
    user = {}

    # Get users for scenario
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    try:
        # Get user by instance_id
        item = table.scan(
            FilterExpression="scenarios.#scenario.#target_id = :i",
            ExpressionAttributeNames={
                "#scenario": scenario_id,
                "#target_id": "target_id"
            },
            ExpressionAttributeValues={
                ":i": created_id
            },
            ProjectionExpression='email, \
                userid, \
                scenarios.#scenario.username, \
                scenarios.#scenario.user_events, \
                scenarios.#scenario.instance_events, \
                scenarios.#scenario.passed \
            '
        )['Items'][0]
    except IndexError:
        logger.exception(f"There is no user with target {created_id}")
        return 1

    # Read user data to map 
    if not item['scenarios'][scenario_id]['passed']:
        user['username'] = item['scenarios'][scenario_id]['username']
        user['email'] = item['email']
        user['userid'] = item['userid']
        user['user_events'] = item['scenarios'][scenario_id]['user_events']
        user['target_id'] = created_id
        user['cheat'] = False

        # Get trail events and created instance id
        check_user_trail = get_trail_events_by_user(user['username'],
                                                    user['user_events'],
                                                    FINALIZE_STEP)
        user['user_events'] = check_user_trail['events']
        user['instances'] = check_user_trail['instances']

        # if instance not created user is cheater
        if not user['instances']:
            user['cheat'] = True
            user['instance_events'] = []
        else:
            for instance in user['instances']:
                logger.info(f"Process instance: {instance} ")
                check_instance_trail = get_trail_events_by_user(instance, [],
                                                                FINALIZE_STEP_I)
                user['instance_events'] = check_instance_trail['events']
                if check_instance_trail['instances'] != None:
                    if user['target_id'] in check_instance_trail['instances']:
                        logger.info(get_events_names(user['user_events']))
                        for step in STEPS:
                            if step not in get_events_names(
                                    user['user_events']):
                                logger.info("first")
                                logger.info(step)
                                user['cheat'] = True
                                break
                            else:
                                user['cheat'] = False
                        break
                    else:
                        logger.info("second ")
                        # print("second")
                        user['cheat'] = True
                else:
                    continue
        # count total time
        total_time = count_total_time(user['user_events'])
        # update user at db 
        updated = table.update_item(
            Key={
                'userid': user['userid']
            },
            UpdateExpression="set scenarios.#scenario.passed = :r,\
                scenarios.#scenario.cheat = :c,\
                scenarios.#scenario.#uev = :u,\
                scenarios.#scenario.#iev = :i,\
                scenarios.#scenario.#total_time = :t",
            ExpressionAttributeNames={
                "#scenario": scenario_id,
                "#uev": "user_events",
                "#iev": "instance_events",
                "#total_time": "total_time"
            },
            ExpressionAttributeValues={
                ':r': True,
                ':c': user['cheat'],
                ':u': user['user_events'],
                ':i': user['instance_events'],
                ':t': total_time
            },
            ReturnValues="UPDATED_NEW"
        )
        logger.info(updated)
        send_email(user['email'], user['userid'])


def get_trail_events_by_user(username, user_events, find_step):
    # Connect to cloudtrail by boto3
    trail = boto3.client('cloudtrail')

    # Create return map
    # user = {}
    # user['instances'] = []
    # user['events'] = user_events
    user = {'instances': [], 'events': user_events}

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
            event_list.append({
                "name": event['EventName'],
                "time": event['EventTime'].strftime("%d-%b-%Y (%H:%M:%S.%f)")
            })
            event = json.loads(event['CloudTrailEvent'])
            if event['eventName'] == find_step:
                try:
                    user['instances'].append(
                        event['responseElements']['instancesSet']['items'][0][
                            'instanceId'])
                except KeyError:
                    logger.exception("instance not exists ")

    # Get only unique events for db and trail
    if user['events'] == {}:
        user['events'] = []
    user['events'] = unique_events(event_list + user['events'])
    if len(user['instances']) == 0:
        user['instances'] = None
    return user


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
    return events


# Get only unique events
def unique_events(event_list):
    events = []
    for event in event_list:
        if event not in events:
            events.append(event)
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
