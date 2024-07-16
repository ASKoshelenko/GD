#!/usr/bin/python3

import sys
import boto3
import time

from botocore.exceptions import ClientError
# Process parameters
profile       = sys.argv[1]
scenario_id   = sys.argv[2]
dbName        = sys.argv[3]
email         = sys.argv[4]
userKeyId     = sys.argv[5]
userKeySecret = sys.argv[6]
username      = sys.argv[7]
attempts = 0
timeout = 9

def updateItem(profile ,scenario_id ,dbName ,email ,userKeyId ,username, attempts) :
    # Initialize session
    session = boto3.Session(profile_name=profile)

    # Get users for scenario
    dynamodb = session.resource('dynamodb')
    dynamodb_client = session.client('dynamodb')
    table = dynamodb.Table(dbName)
    try :
        # Update user at db events
        update = table.update_item(
            Key={
                'email': email
            },
            UpdateExpression='SET \
                scenarios.#scenario.#access_key = :a,\
                scenarios.#scenario.#secret_key = :s,\
                scenarios.#scenario.#username   = :u',
            ExpressionAttributeNames = {
                "#scenario"   : scenario_id,
                "#access_key" : "access_key",
                "#secret_key" : "secret_key",
                "#username"   : "username"
            },
            ExpressionAttributeValues={
                ':a': userKeyId,
                ':s': userKeySecret,
                ':u': username
            },
            ReturnValues="UPDATED_NEW"
        )
        print(update)
    except Exception as e:
        print(e.response['Error'])
        print("catch1"+ str(attempts))
        if attempts > timeout :
            print("there was 5 tryes")
            return 1
        time.sleep(attempts*2)
        attempts+=1
        updateItem(profile ,scenario_id ,dbName ,email ,userKeyId ,username, attempts)
    try :
        time.sleep(5)
        # session
        session = boto3.Session(profile_name=profile)

        # Get users for scenario
        dynamodb = session.resource('dynamodb')
        dynamodb_client = session.client('dynamodb')
        table = dynamodb.Table(dbName)
        item = table.scan(
                FilterExpression = "email = :e",
                ProjectionExpression = "scenarios.#scenario.access_key",
                ExpressionAttributeNames = {
                    "#scenario": scenario_id
                },
                ExpressionAttributeValues = {
                    ":e" : email
                }
            )['Items'][0]
        print(item)
        if item == {} :
            print("try"+ str(attempts))
            attempts+=1
            updateItem(profile ,scenario_id ,dbName ,email ,userKeyId ,username, attempts)

    except IndexError:
        print("catch2 "+ str(attempts))
        if attempts > timeout :
            print("there was 5 tryes")
            return 1
        time.sleep(attempts*2)
        attempts+=1
        updateItem(profile ,scenario_id ,dbName ,email ,userKeyId ,username, attempts)
   

updateItem(profile ,scenario_id ,dbName ,email ,userKeyId ,username, attempts)