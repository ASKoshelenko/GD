import boto3, time

def lambda_handler(event, context):
    # initialize boto3 client and get table 
    dynamodb = boto3.client('dynamodb')
    
    # get user from event 
    data = event['responsePayload']
    user = str(data).split(':')[0]
    cheater = str(data).split(':')[1]
    # check if user exists
    response = dynamodb.scan(TableName='user',
    ScanFilter = 
        {
            'username':{
                'AttributeValueList':[ {"S":user} ],
                "ComparisonOperator": "EQ"
            }
        }
    )
    print(response)
    if response['Count'] != 0 :
        
        # if not passed send congratulation message
        if not response['Items'][0]['passed']['BOOL'] :
            topicArn = response['Items'][0]['topic_arn']['S']
            send_message(topicArn,cheater,response['Items'][0]['email']['S'])
            
    # print to log that user not exists in dynamo db
    else : print("User with username: "+user+" not exists")
    
# Publish a message to the specified SNS topic
def send_message(topicArn, cheater, email):
    sns = boto3.client('sns')
    if cheater == 'not cheater':
        cheater = False
        sns.publish(
            TopicArn = topicArn,
            Message = 'Congratulations, you are successfully comlepted first scenario of EPAM AWS security challenge'  
        )
    else :
        cheater = True
        sns.publish(
            TopicArn = topicArn,
            Message = 'Congratulations, you are successfully comlepted first scenario of EPAM AWS security challenge, but you are cheater!!!'  
        )
        
    # update database avoid resending completion email
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('user')
    response = table.update_item(
        Key={
            'email': email,
        },
        UpdateExpression="set passed = :r, cheat= :c",
        ExpressionAttributeValues={
            ':r': True,
            ':c': cheater
        },
        ReturnValues="UPDATED_NEW"
    )
    