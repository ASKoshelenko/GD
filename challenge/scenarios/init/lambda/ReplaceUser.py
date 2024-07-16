import boto3
import logging

logs = logging.getLogger()
logs.setLevel(logging.INFO)

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    try: 
        userid = event["userid_for_replace"]
        email_for_replace = event["email_for_replace"]
        username_for_replace = event["username_for_replace"]
    except KeyError:
        logs.exception('Payload is incorrect {\
        "userid_for_replace": <userid_for_replace>,\
        "email_for_replace": <email_for_replase>,\
        "username_for_replace": <username_for_replace>')
        raise Exception('Payload is incorrect try to use { \
        "userid_for_replace": <userid_for_replace>, \
        "email_for_replace": <email_for_replase>, \
        "username_for_replace": <username_for_replace>')
    try:
        userid = event["userid_for_replace"]
        item = table.get_item(
            Key={"userid": userid},
            ProjectionExpression='notifications'
            )['Item']['notifications']
        for key_list_in_item in item:
            if key_list_in_item != "test":
                table.update_item(
                    Key={
                        'userid': userid,
                    },
                    UpdateExpression='REMOVE notifications.#key_list_in_item',
                    ExpressionAttributeNames={
                        '#key_list_in_item': key_list_in_item
                    }
                )
        update = table.update_item(
            Key={
                'userid': userid
            },
            UpdateExpression="SET email= :var1, username= :var2, category= :var3",
            ExpressionAttributeValues={
                ':var1': email_for_replace,
                ':var2': username_for_replace,
                ':var3': 'student'
            },

            ReturnValues="UPDATED_NEW"
        )
        logs.info(update)
        return "Database was updated"
    except KeyError:
        logs.exception(f'{userid} not found in database. Use correct user ID')
        raise Exception((f'{userid} not found in database. Use correct user ID'))
