import json
import boto3
import os
from datetime import datetime, timedelta
import logging

CUSTOM_RANGE_FOR_CHECKING_CLOUDTRAIL_EVENTS = 7

# Create own logger and set log display level
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(data, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    # Get mail current user
    email = os.environ['UserEmail']

    # Get userid for current user
    userid = os.environ['UserId']

    # Get scenario id from environment
    scenario_id = os.environ['ScenarioName']

    # Get logs for user email
    logs = log_getting(scenario_id, userid)

    if len(data.values()) > 1:
        return {
            'Message': 'To many keys, I`m unbreakable!!!',
            'Tip': 'If you want to complete scenario try to uset '
                   'the correct payload',
            'TheCorrectPayload': '{"Key":"your_secretkey_from_rds"}'
        }
    elif len(data.values()) == 0:
        return {
            'Message': 'Try to add payload',
            'Tip': 'If you want to complete scenario, try to use '
                   'the correct payload',
            'TheCorrectPayload': '{"Key":"your_secretkey_from_rds"}'
        }

    for key in data.values():
        try:
            # Get user information from DB
            user = table.scan(
                FilterExpression='scenarios.#scenario.completion_key = :i',
                ExpressionAttributeNames={
                    "#scenario": scenario_id
                },
                ExpressionAttributeValues={
                    ":i": key
                },
                ProjectionExpression=' \
                    email, \
                    userid, \
                    scenarios.#scenario.passed \
                '
            )['Items'][0]

            # Verifying that the key belongs to the user
            if email == user['email']:
                if not user['scenarios'][scenario_id]['passed']:
                    #  Change of state passing scenario to true
                    total_time = count_total_time(
                        logs['check_user_trail1']['events'],
                        logs['check_user_trail2']['events'])
                    updated = table.update_item(
                        Key={
                            'userid': user['userid']
                        },
                        UpdateExpression='SET scenarios.#scenario.#passed = :l,'
                                         ' scenarios.#scenario.#total_time = :t',
                        ExpressionAttributeNames={
                            "#scenario": scenario_id,
                            "#passed": "passed",
                            "#total_time": "total_time"
                        },
                        ExpressionAttributeValues={
                            ':l': True,
                            ':t': total_time
                        },
                        ReturnValues="UPDATED_NEW"
                    )

                    # Send congrats message
                    logger.info(updated)
                    send_email(email, user['userid'])
                    return f"Congratulations, the key: {key} is yours\n"
                else:
                    return f"Congratulations, the key: {key} " \
                           f"is yours, but you are already pass it"
            else:
                return "The key: " + key + " is not yours\n"

        except IndexError:
            return f"Key {key} not exists\n"
        except Exception as e:
            return {
                'Error': str(e),
                'Message': 'And you tried to broke me by this, '
                           'It is so unfair of you!!',
                'Remember': 'I`m unbrekable!!!',
                'Tip': 'If you wanna complete scenario try to uset '
                       'the correct payload',
                'TheCorrectPayload': '{"Key":"your_secretkey_from_rds"}'
            }


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


def log_getting(scenario_id, userid):
    # Connect to dynamodb table
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    # Get item to update
    item = table.get_item(
        Key={"userid": userid},
        ProjectionExpression=' \
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
        user['user1_events'] = item['scenarios'][scenario_id]['user1_events']
        user['user2_events'] = item['scenarios'][scenario_id]['user2_events']
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
                'userid': userid
            },
            UpdateExpression='SET scenarios.#scenario.#uev1 = :u1,'
                             ' scenarios.#scenario.#uev2 = :u2',
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
        return {
            "check_user_trail1": check_user_trail1,
            "check_user_trail2": check_user_trail2
        }


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


def unique_events(event_list):
    events = []
    for event in event_list:
        if event not in events:
            events.append(event)
    return events


def count_total_time(events1, events2):
    durations = []
    end = datetime.now()

    if events1:
        events = events1
    elif events2:
        events = events1
    else:
        durations.append(
            {
                'start': "something went wrong",
                'end': end.strftime("%d-%b-%Y (%H:%M:%S.%f)"),
                'duration': "0"
            })
        return durations
    events = events[::-1]
    start = datetime.strptime(events[0]['time'], '%d-%b-%Y (%H:%M:%S.%f)')
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
