import boto3, os, json
 
def lambda_handler(event, context):
    # event['email']
    email = 'iryna_abikh@epam.com'
    resp = send_request(email)
    return(resp)
    
    # From json output selects the "Endpoint" field.
def need_subscription(email, subscriptions):
    for subscription in subscriptions['Subscriptions']:
        if subscription['Endpoint'].lower() == email.lower():
            break
        else:
            return True
    return False

 
def send_request(email):
    # Create an SNS client
    sns = boto3.client('sns')
    
    list_subscriptions_by_topic = sns.list_subscriptions_by_topic(
            TopicArn = 'arn:aws:sns:us-east-1:028764560963:MyTopic'
        )
    print(list_subscriptions_by_topic)
    if need_subscription(email, list_subscriptions_by_topic):
        print('Subscribing')
        response = sns.subscribe(
            TopicArn = 'arn:aws:sns:us-east-1:028764560963:MyTopic',
            Protocol = 'email',
            Endpoint = email,
            ReturnSubscriptionArn=True
        )
        print(response)
        
    
    # Publish a message to the specified SNS topic
    response1 = sns.publish(
        TopicArn = 'arn:aws:sns:us-east-1:028764560963:MyTopic',    
        Message = "Hello from Lambda by SNS",    
    )
 
    #Print out the response
    print(response1)
    