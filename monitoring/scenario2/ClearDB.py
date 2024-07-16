import boto3
import logging

#Create own looger and set log display level 
logger = logging.getLogger()                        
logger.setLevel(logging.INFO)


def lambda_handler(event, context):

    # Initialiaze dynamoDB resource
    dynamodb = boto3.resource('dynamodb')
    
    # Connect to table
    table = dynamodb.Table('users')
    
    # Get not confirmed users from DB
    users = table.scan(
        FilterExpression = "subscription = :i",
        ExpressionAttributeValues = {
            ":i" : "pending"
        }
    )['Items']
    
    # Remove users from db
    for user in users:
        response = table.delete_item(
            Key= {
                "email":user['email']
            }
        )
        logger.info(response)
    return 