import boto3
import json
import os
import logging
from datetime import datetime, timedelta

CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS = 7

# Create own logger and set log display level 
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    # Init scenario id variable
    scenario_id = os.environ['ScenarioName']

    # Connect to dynamoDB table
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    # Get primary keys list
    userids = table.scan(
        ProjectionExpression='userid'
    )['Items']

    # Process all items
    for userid in userids:
        item = table.get_item(
            Key={"userid": userid['userid']},
            ProjectionExpression=' \
                userid, \
                email, \
                scenarios.#scenario.username_user1, \
                scenarios.#scenario.username_user2, \
                scenarios.#scenario.user1_events, \
                scenarios.#scenario.user2_events, \
                scenarios.#scenario.passed \
            ',
            ExpressionAttributeNames={
                "#scenario": scenario_id
            }
        )['Item']

        # Init user collection
        user = {}

        # Read user data to map
        if not item['scenarios'][scenario_id]['passed']:
            user['username1'] = item['scenarios'][scenario_id]['username_user1']
            user['username2'] = item['scenarios'][scenario_id]['username_user2']
            user['email'] = item['email']
            user['userid'] = item['userid']
            user['user1_events'] = item['scenarios'][scenario_id][
                'user1_events']
            user['user2_events'] = item['scenarios'][scenario_id][
                'user2_events']
            user['cheat'] = False
            logger.info(user)

            # Get trail events and created instance id
            check_user_trail1 = get_trail_events_by_user(user['username1'],
                                                         user['user1_events'])
            check_user_trail2 = get_trail_events_by_user(user['username2'],
                                                         user['user2_events'])

            # update user at db
            updated = table.update_item(
                Key={
                    'userid': user['userid']
                },
                UpdateExpression="set scenarios.#scenario.#uev1 = :u1, "
                                 "scenarios.#scenario.#uev2 = :u2",
                ExpressionAttributeNames={
                    "#scenario": scenario_id,
                    "#uev1": "user1_events",
                    "#uev2": "user2_events"
                },
                ExpressionAttributeValues={
                    ':u1': check_user_trail1['events'],
                    ':u2': check_user_trail2['events']
                },
                ReturnValues="UPDATED_NEW"
            )
            logger.info(updated)


def get_trail_events_by_user(username, user_events):
    # Connect to cloudtrail by boto3
    trail = boto3.client('cloudtrail')

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

    # Get only unique events for db and trail
    if user['events'] == {}:
        user['events'] = []
    user['events'] = unique_events(event_list + user['events'])
    return user


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


def get_date_range():
    # Get current date
    current_date = datetime.now()

    # Get StartTime
    days_ago_date = current_date - timedelta(
        days=CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS)

    current_date_str = current_date.isoformat()
    days_ago_str = days_ago_date.isoformat()
    return current_date_str, days_ago_str
