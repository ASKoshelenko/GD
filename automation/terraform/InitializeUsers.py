import boto3, time
from boto3.dynamodb.conditions import Key, Attr
import logging

#Create own looger and set log display level 
logger = logging.getLogger()                        
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    sns = boto3.client('sns')
    
    # Searching for not active users for to change their Subscription status 
    with table.batch_writer() as batch:
        logger.info("Searching for not active users")
        for item in table.scan(FilterExpression=Attr('subscription').ne('active'))['Items']:
            logger.info(f"Proccessing {item['email']}")
    # Creation of the "topic_arn" item from email
            aws_topic_arn = None
            email_str = item['email'].lower().replace('@','_').replace('.','_')
            for topic in sns.list_topics()['Topics']:
                if email_str in topic['TopicArn']:
                    aws_topic_arn = topic['TopicArn']
                    logger.info(f"Found existing topic {aws_topic_arn}")
                    break
                
            # Creation item in the database 
            if aws_topic_arn != None:
                item.update({"topic_arn":aws_topic_arn})
            else:
                try:
                    logger.info("Adding new topic")
                    response = sns.create_topic(Name=email_str)
                    aws_topic_arn = response['TopicArn']
                    item.update({"topic_arn":aws_topic_arn})
                except Exception:
                    logger.exception("Exception ")
                    
            # Verify user subscription       
            if aws_topic_arn:
                aws_subscription_arn = None
                for subscription in sns.list_subscriptions_by_topic(TopicArn=aws_topic_arn)['Subscriptions']:
                    if subscription['Endpoint'] == item['email'].lower():
                        logger.info("Subscription already exist")
                        aws_subscription_arn = subscription['SubscriptionArn']
                        break

                # User subscription creation  and database content change 
                if aws_subscription_arn == 'PendingConfirmation':
                    logger.info("Subscription pendingt")
                    item.update({"subscription":"pending"})
                elif aws_subscription_arn is None:
                    try:
                        logger.info("Adding new subscription")
                        sns.subscribe(
                            TopicArn=aws_topic_arn,
                            Protocol='email',
                            Endpoint=item['email'].lower()
                        )
                        item.update({"subscription":"pending"})
                        item.update({"subscription_date":int(time.time())})
                    except Exception:
                        logger.exception("Exception ")
                else:
                    logger.info("Subscription active")
                    item.update({"subscription":"active"})
            batch.put_item(Item=item)
    return {
        'statusCode': 200,
        'body': ""
    }
