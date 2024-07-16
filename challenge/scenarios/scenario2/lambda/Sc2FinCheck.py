import json
import boto3
import os
from datetime import datetime
import logging

# Create own looger and set log display level
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(data, context):
    # Initialize db
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    # Get email for current user
    email = os.environ['UserEmail']
    userid = os.environ['UserName']

    # Get scenario id from environment
    scenario_id = os.environ['ScenarioName']

    if len(data.values()) > 1:
        return {
            'Message': 'To many keys, I`m unbreakable!!! ',
            'Tip': 'If you wanna complete scenario try to uset the correct '
                   'payload',
            'TheCorrectPayload': '{"Key":"your_secretkey_from_rds"}'
        }
    elif len(data.values()) == 0:
        return {
            'Message': 'Try to add payload',
            'Tip': 'If you wanna complete scenario, try to use the correct'
                   ' payload',
            'TheCorrectPayload': '{"Key":"your_secretkey_from_rds"}'
        }

    # Process input data
    for key in data.values():
        try:
            # Get user information from DB
            user = table.scan(
                FilterExpression="scenarios.#scenario.completion_key = :i",
                ExpressionAttributeNames={
                    "#scenario": scenario_id
                },
                ExpressionAttributeValues={
                    ":i": key
                },
                ProjectionExpression=' \
                    email, \
                    userid,\
                    scenarios.#scenario.passed, \
                    topic_arn, \
                    username \
                '
            )['Items'][0]

            # Verifying that the key belongs to the user
            if userid == user['userid']:
                if not user['scenarios'][scenario_id]['passed']:
                    # Change of state passing scenario to true
                    total_time = count_total_time(userid)
                    updated = table.update_item(
                        Key={
                            'userid': user['userid']
                        },
                        UpdateExpression="set scenarios.#scenario.#passed = :l,"
                                         " scenarios.#scenario.#total_time = :t",
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
                    send_email(user['email'], user['userid'])
                    logger.info(f"Congratulations, the key: {key} is yours")
                    return f"Congratulations, the key: {key} is yours\n"
                else:
                    logger.info(
                        f"Congratulations, the key: {key} is yours, "
                        f"but you are already pass it")
                    return f"Congratulations, the key:{key} " \
                           f"is yours, but you are already pass it"
            else:
                logger.info(f"The key: {str(key)} is not yours")
                return "The key " + str(key) + " is not yours\n"

        except IndexError:
            logger.exception("IndexError ")
            return "Key " + str(key) + " not exists\n"
        except Exception as e:
            logger.exception("Error ")
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
            'userid':userid,
            'placeholders': {
                'ScenarioName': os.environ['ScenarioName']
            }
        })
    )


def count_total_time(userid):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    scenario_id = "scenario1"
    durations = []
    end = datetime.now()
    try:
        # Get item to update
        item = table.get_item(
            Key={"userid": userid},
            ProjectionExpression=' \
                scenarios.#scenario.total_time \
            ',
            ExpressionAttributeNames={
                "#scenario": scenario_id
            }
        )['Item']
        start = datetime.strptime(
            item['total_time'][0]['end'], '%d-%b-%Y (%H:%M:%S.%f)')

    except Exception as e:
        logger.exception(f"Error {str(e)}")
        durations.append(
            {
                'start': "scenario1 is not completed",
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

    logger.info(duration)
    return durations
