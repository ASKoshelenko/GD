import boto3, time
from boto3.dynamodb.conditions import Key, Attr


def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    sns = boto3.client('sns')
    user = {}
    
    # Searching for not active users for to change their Subscription status 
    print("Searching for not active users")
    for item in table.scan(
            FilterExpression = Attr('subscription').ne('active'),
            ProjectionExpression = "subscription, email, topic_arn, subscription_date"            
        )['Items']:
        print(item)
        user = item.copy()
        
        # Check item attributes existing
        try :
            print( "Processing " + item['email'] + " " + item['subscription'])
        except KeyError:
            print( "Processing " + item['email'])
            item['subscription'] = 'pending'


        if  item['subscription'] != 'active':
            # Update or create topic arn 
            try :
                print("Aready exists in DB " + item['topic_arn'])
            except KeyError:
                item['topic_arn'] = None
                email_str = item['email'].lower().replace('@','_').replace('.','_')
                topic_str = "arn:aws:sns:eu-central-1:839606382402:"+email_str
                for topic in sns.list_topics()['Topics']:
                    if topic_str in topic['TopicArn']:
                        item['topic_arn'] = topic['TopicArn']
                        print("Found existing topic " + item['topic_arn'])
                        break
                    
                # If topic not exists add topic and update item topic arn
                if item['topic_arn'] == None:
                    try:
                        print("Adding new topic")
                        item["topic_arn"] = sns.create_topic(Name=email_str)['TopicArn']
                    except Exception as e:
                        print(e)

                    
            # Verify user subscription       
            if item["topic_arn"]:
                listSubscribtions = []
                try :
                    listSubscribtions = sns.list_subscriptions_by_topic(TopicArn=item["topic_arn"])['Subscriptions']
                    print(listSubscribtions['SubscriptionArn'])
                except Exception as e:
                    print(e)
                    print("there are no topics")
                if listSubscribtions != [] :
                    for subscription in listSubscribtions :
                        print(subscription['SubscriptionArn'])                    
                        if subscription['Endpoint'] == item['email'].lower() and \
                        subscription['SubscriptionArn'] == 'PendingConfirmation':
                            print("Subscription already exists: " + subscription['Endpoint'])
                            item['subscription'] ="pending"
                            try :
                                print(str(item['subscription_date'])+"date exists") 
                            except KeyError:
                                item['subscription_date'] = int(time.time())
                            break
                        else:
                            print("Subscription active")
                            item['subscription'] = "active"
                    
                elif listSubscribtions == []:
                    try:
                        print("Adding new subscription")
                        sns.subscribe(
                            TopicArn = item["topic_arn"],
                            Protocol = 'email',
                            Endpoint = item['email'].lower()
                        )
                        item['subscription'] = "pending"
                        item['subscription_date'] = int(time.time())
                    except Exception as e:
                        print(e)

        if user != item :
            updateItem(item, table)
        else :
            print("user not changed")

def updateItem(item, table):
        # update user at db 
        print("updating Item")
        try:
            print(str(item['subscription_date'])+"date exists") 
        except KeyError:
            item['subscription_date'] = int(time.time())
        updated = table.update_item(
            Key={
                'email': item['email']
            },
            UpdateExpression="set subscription = :s, subscription_date = :d, topic_arn = :t",
            ExpressionAttributeValues={
                ':s': item['subscription'],
                ':d': item['subscription_date'],
                ':t': item['topic_arn']
            },
            ReturnValues="UPDATED_NEW"
        )
        print(updated)
