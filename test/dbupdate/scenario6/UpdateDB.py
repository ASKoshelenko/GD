#!/usr/bin/python3

import sys
import boto3
import time

from botocore.exceptions import ClientError
# Process parameters
profile         = sys.argv[1]
scenario_id     = sys.argv[2]
dbName          = sys.argv[3]
emails          = sys.argv[4].split(" ")
user1KeyIds     = sys.argv[5].split(" ")
user1KeySecrets = sys.argv[6].split(" ")
user1names      = sys.argv[7].split(" ")
user2names      = sys.argv[8].split(" ")
names           = sys.argv[9].split(" ")
randoms         = sys.argv[10].split(" ")
lambdanames     = sys.argv[11].split(" ")
keys = []
for i in range(len(names)) :
    keys.append( str(names[i])+str(randoms[i]) )
attempts = 0
timeout = 9

def updateItems(profile ,scenario_id ,dbName ,emails ,user1KeyIds , user1KeySecrets, user1names,lambdanames, user2names, keys, attempts) :
    # Initialize session
    session = boto3.Session(profile_name=profile)

    # Get users for scenario
    dynamodb = session.resource('dynamodb')
    dynamodb_client = session.client('dynamodb')
    table = dynamodb.Table(dbName)
    # try :
    j=0
    while j<len(emails):
        time.sleep(30)
        for i in range(5):
            try:
                print(emails[j+i])
                # Update user at db events
                update = table.update_item(
                    Key={
                        'email': emails[j+i]
                    },
                    UpdateExpression='SET \
                        scenarios.#scenario.#access_key1  = :b,\
                        scenarios.#scenario.#secret_key1  = :c,\
                        scenarios.#scenario.#username1    = :d,\
                        scenarios.#scenario.#username2    = :g,\
                        scenarios.#scenario.#key          = :k,\
                        scenarios.#scenario.#lambda       = :l,\
                        scenarios.#scenario.#user1_events = :e,\
                        scenarios.#scenario.#user2_events = :v\
                    ',
                    ExpressionAttributeNames = {
                        "#scenario"    : scenario_id,
                        "#access_key1" : "access_key_user1",
                        "#secret_key1" : "secret_key_user1",
                        "#username1"   : "username_user1",
                        "#username2"   : "username_user2",
                        "#key"         : "completion_key",
                        "#lambda"      : "completion_lambda",
                        "#user1_events": "user1_events",
                        "#user2_events": "user2_events"
                    },
                    ExpressionAttributeValues={
                        ':b': user1KeyIds[j+i],
                        ':c': user1KeySecrets[j+i],
                        ':d': user1names[j+i],
                        ':g': user2names[j+i],
                        ':k': keys[j+i],
                        ':l': lambdanames[j+i],
                        ':e': [],
                        ':v': []
                    },
                    ReturnValues="UPDATED_NEW"
                )
                print(update)
            except IndexError:
                return 0
        j+=i+1        
    # except Exception as e:
    #     print(e.response['Error'])
    #     print("catch1"+ str(attempts))
    #     if attempts > timeout :
    #         print("there was 5 tryes")
    #         return 1
    #     time.sleep(attempts*2)
    #     attempts+=1
    #     updateItem(profile ,scenario_id ,dbName ,email ,userKeyId ,username, attempts)
    # try :
    #     time.sleep(5)
    #     # session
    #     session = boto3.Session(profile_name=profile)

    #     # Get users for scenario
    #     dynamodb = session.resource('dynamodb')
    #     dynamodb_client = session.client('dynamodb')
    #     table = dynamodb.Table(dbName)
    #     item = table.scan(
    #             FilterExpression = "email = :e",
    #             ProjectionExpression = "scenarios.#scenario.access_key",
    #             ExpressionAttributeNames = {
    #                 "#scenario": scenario_id
    #             },
    #             ExpressionAttributeValues = {
    #                 ":e" : email
    #             }
    #         )['Items'][0]
    #     print(item)
    #     if item == {} :
    #         print("try"+ str(attempts))
    #         attempts+=1
    #         updateItem(profile ,scenario_id ,dbName ,email ,userKeyId ,username, attempts)

    # except IndexError:
    #     print("catch2 "+ str(attempts))
    #     if attempts > timeout :
    #         print("there was 5 tryes")
    #         return 1
    #     time.sleep(attempts*2)
    #     attempts+=1
    #     updateItem(profile ,scenario_id ,dbName ,email ,userKeyId ,username, attempts)
   
updateItems(profile ,scenario_id ,dbName ,emails ,user1KeyIds , user1KeySecrets, user1names,lambdanames, user2names, keys, attempts)