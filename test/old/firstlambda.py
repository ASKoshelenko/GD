import boto3, os, json
 
def lambda_handler(event, context):
    # event['email']
    message = 'Hello from Lambda by SNS'
    email = 'my@mail.com'
    topicArn ='arn:aws:sns:us-east-1:028764560963:MyTopic'
    resp = send_request(email, topicArn, message)
    return(resp)
    
# From json output selects the "Endpoint" field.
def need_subscription(email, subscriptions):
    for subscription in subscriptions['Subscriptions']:
        if subscription['Endpoint'].lower() == email.lower():
            break
        else:
            return True
    return False

 
def send_request(email, topicArn, message):
    # Create an SNS client
    sns = boto3.client('sns')
    
    list_subscriptions_by_topic = sns.list_subscriptions_by_topic(
            TopicArn = topicArn
    )
    print(list_subscriptions_by_topic)
    if need_subscription(email, list_subscriptions_by_topic):
        print('Subscribing')
        response = sns.subscribe(
            TopicArn = topicArn,
            Protocol = 'email',
            Endpoint = email,
            ReturnSubscriptionArn=True
        )
        print(response)