import boto3
import json
import os
import re
import logging

# Create own logger and set log display level
logger = logging.getLogger()
logger.setLevel(logging.INFO)

BUCKET = os.environ['bucketName']


def lambda_handler(event, context):
    """
    main function
    """
    # Collection for dashboard items
    student = []

    # Get users for scenario
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    # Get table items
    users = table.scan(
        ProjectionExpression='userid'
    )['Items']
    # To-Do Error in 40 line An error occurred (ValidationException)
    # Read emails and get scenario
    for user in users:
        item = table.get_item(
            Key={"userid": user['userid']},
            ProjectionExpression='category, scenarios, email, username'
        )['Item']
        if item['category'] == 'student':
            logger.info(
                f"item['scenarios']  ==== {item['scenarios']}")
            student.append(generate_dashboard_object(item))
        else:
            pass
    upload(student, 'data')
    # refresh_time()


def generate_dashboard_object(item):
    """
    Create the user scenario object
    var userData = [
        {
            username: "first_name second_name",
            scenarios: [
                { name: "scenario_1", passed: true },
                { name: "scenario_2", passed: true },
                { name: "scenario_3", passed: false },
            ],
        },
    ]
    """
    obj = {'username': item['username']}
    obj["scenarios"] = []
    scenarios = item['scenarios']
    print(scenarios)
    for key in scenarios:
        if (("username" in scenarios[key]) or (
                "username_user1" in scenarios[key])):
            scenario_name = camel_to_snake(key)
            passed = "pass" if scenarios[key]["passed"] else "failed"
            # TODO To add a check for the end time of scenario completion.
            # passed = scenarios[key]["completion"]
            obj["scenarios"].append({"name": scenario_name, "passed": passed})
    logger.info("Result - generate_dashboard_object = %s", obj)
    return obj


def upload(data, group):
    """
    Update dashboard s3 objects
    """
    # data = sorted(data, key=lambda x: int(x['value']), reverse=True)
    data_str = 'var userData = ' + json.dumps(data, indent=4,
                                              sort_keys=True) + ";"
    data_byte = str.encode(data_str)
    s3 = boto3.client('s3')

    # upload updated dashboard
    s3.put_object(
        ACL='public-read',
        Bucket=BUCKET,
        Key='js/' + group + '.js',
        Body=data_byte
    )
    logger.info(f"{group} updated")


def camel_to_snake(camel_str):
    """Conver from CamelCase to snake_case"""
    # Replace all numbers to _
    camel_str = re.sub('(\d)', r'_\1', camel_str)
    # Replase all Upper symbols to lower with underscore
    camel_str = re.sub('([A-Z])', r'_\1', camel_str).lower()
    # Delete firs underscore if exists
    if camel_str.startswith('_'):
        camel_str = camel_str[1:]
    return camel_str

# def refresh_time():
#     from datetime import datetime
#     start = datetime.combine(datetime.now().today(), datetime.now().time())
#     end = datetime.combine(datetime.now().today(),
#                            datetime.strptime('3:00PM', '%I:%M%p').time())
#     lasts = end - start
#     seconds = lasts.seconds
#     lasts = str(seconds // 3600).zfill(2) + ":" + str(seconds // 60 % 60) \
#         .zfill(2)
#     if end < start:
#         lasts = "00:00"
#     data_byte = str.encode(
#         'document.getElementById("time").innerHTML = "' + lasts + '";')
#     # upload updated dashboard
#     s3 = boto3.client('s3')
#     s3.put_object(
#         ACL='public-read',
#         Bucket=BUCKET,
#         Key='js/time.js',
#         Body=data_byte
#     )
