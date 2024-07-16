#!/usr/bin/python3

import sys
import boto3
import time

from botocore.exceptions import ClientError
# Process parameters
profile        = sys.argv[1]
scenario_id    = sys.argv[2]
dbName         = sys.argv[3]
emails         = sys.argv[4].split(" ")
userKeyIds     = sys.argv[5].split(" ")
userKeySecrets = sys.argv[6].split(" ")
usernames      = sys.argv[7].split(" ")
target_ip      = sys.argv[8]
target_lambdas = sys.argv[9].split(" ")
completion_keys= sys.argv[10].split(" ")
attempts = 0
timeout = 9

def updateItems(profile ,scenario_id ,dbName ,emails ,userKeyIds , userKeySecrets, usernames, target_ip, target_lambdas, completion_keys, attempts) :
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
                print(usernames[j+i])
                # Update user at db events
                update = table.update_item(
                    Key={
                        'email': emails[j+i]
                    },
                    UpdateExpression='SET \
                        scenarios.#scenario.#access_key    = :a,\
                        scenarios.#scenario.#secret_key    = :s,\
                        scenarios.#scenario.#username      = :u,\
                        scenarios.#scenario.#target_ip     = :i,\
                        scenarios.#scenario.#target_lambda = :l,\
                        scenarios.#scenario.#key           = :k \
                    ',
                    ExpressionAttributeNames = {
                        "#scenario"     : scenario_id,
                        "#access_key"   : "access_key",
                        "#secret_key"   : "secret_key",
                        "#username"     : "username",
                        "#target_ip"    : "target_ip",
                        "#target_lambda": "target_lambda",
                        "#key"          : "completion_key"
                    },
                    ExpressionAttributeValues={
                        ':a': userKeyIds[j+i],
                        ':s': userKeySecrets[j+i],
                        ':u': usernames[j+i],
                        ':i': target_ip,
                        ':l': target_lambdas[j+i],
                        ':k': completion_keys[j+i]
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
   
updateItems(profile ,scenario_id ,dbName ,emails ,userKeyIds , userKeySecrets, usernames, target_ip, target_lambdas, completion_keys, attempts)