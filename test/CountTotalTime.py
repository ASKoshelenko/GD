import json, boto3
from datetime import datetime

def lambda_handler(data, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    scenario_id ="scenario1" #os.environ['ScenarioName']
    # Get item to update
    item = table.get_item(
        Key={ "email":"Anatolii_Hromov@epam.com" },
        ProjectionExpression = ' \
            scenarios.#scenario.events \
        ',
        ExpressionAttributeNames = {
            "#scenario" : scenario_id
        }
    )['Item']
    events = item['scenarios'][scenario_id]['events'][::-1]
    print(events)
    # names = getEventsNames(events)
    durations = []
    for event in events :
        if event['name'] == 'SetDefaultPolicyVersion':
            start = datetime.strptime(events[0]['time'], '%d-%b-%Y (%H:%M:%S.%f)')
            end = datetime.strptime(event['time'], '%d-%b-%Y (%H:%M:%S.%f)')
            duration = end - start
            durations.append(
            {
                'start':start.strftime("%d-%b-%Y (%H:%M:%S.%f)"),
                'end':end.strftime("%d-%b-%Y (%H:%M:%S.%f)"),
                'duration':str(duration)
            })
            
    print(durations) 