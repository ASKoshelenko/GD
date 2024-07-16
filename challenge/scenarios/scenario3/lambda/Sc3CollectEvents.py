import json
import boto3
import os
import logging
from datetime import datetime, timedelta

CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS = 7

# Create own logger and set log display level 
logger = logging.getLogger()
logger.setLevel(logging.INFO)

FINALIZE_STEP = 'RunInstances'

# Init scenario id variable
scenario_id = os.environ['ScenarioName']

# Get users for scenario
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')


def lambda_handler(event, context):
    # Init user collection
    user = {}

    # Get primary keys list
    userids = table.scan(
        ProjectionExpression='userid'
    )['Items']

    # Process all items
    for userid in userids:
        item = table.get_item(
            Key={"userid": userid['userid']},
            ProjectionExpression='email,\
                userid,\
                scenarios.#scenario.username, \
                scenarios.#scenario.user_events, \
                scenarios.#scenario.instance_events, \
                scenarios.#scenario.passed \
            ',
            ExpressionAttributeNames={
                "#scenario": scenario_id
            }
        )['Item']
        if not item['scenarios'][scenario_id]['passed']:

            # Get all parameters
            user_email = item['email']
            instance_events = item['scenarios'][scenario_id]['instance_events']
            user_name = item['scenarios'][scenario_id]['username']
            user_events = item['scenarios'][scenario_id]['user_events']
            user = get_trail_events_by_username(user_name, user_events,
                                                FINALIZE_STEP)
            user_events = user['events']

            # if instances was created update instance events
            if user['instances']:
                for instance in user['instances']:
                    instance_events = unique_events(instance_events +
                                                    get_trail_events_by_username(
                                                        instance,
                                                        instance_events,
                                                        "")['events'])
            print(userid)
            print(user_events)
            print(instance_events)
            db_update(userid['userid'], user_events, instance_events)
    return


def get_trail_events_by_username(username, user_events, find_step):
    # Connect to cloudtrail by boto3
    trail = boto3.client('cloudtrail')
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
                    logging.exception('instance not exists')

    # Get only unique events for db and trail
    if user['events'] == {}:
        user['events'] = []

    user['events'] = unique_events(event_list + user['events'])

    if len(user['instances']) == 0:
        user['instances'] = None
    logger.info(user)
    return user


def db_update(user_id, user_events, instance_events):
    logger.info('Update DB')
    # update user at db 
    updated = table.update_item(
        Key={
            'userid': user_id
        },
        UpdateExpression="set scenarios.#scenario.#uev = :u,"
                         " scenarios.#scenario.#iev = :i",
        ExpressionAttributeNames={
            "#scenario": scenario_id,
            "#uev": "user_events",
            "#iev": "instance_events"
        },
        ExpressionAttributeValues={
            ':u': user_events,
            ':i': instance_events
        },
        ReturnValues="UPDATED_NEW"
    )
    logger.info(updated)


# Get only unique events
def unique_events(event_list):
    events = []
    for event in event_list:
        if event not in events:
            events.append(event)
    logger.info(events)
    return events


def get_date_range():
    # Get current date
    current_date = datetime.now()

    # Get StartTime
    days_ago_date = current_date - timedelta(
        days=CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS)

    current_date_str = current_date.isoformat()
    days_ago_str = days_ago_date.isoformat()
    return current_date_str, days_ago_str
