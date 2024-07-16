import json, boto3, time

# Initialize boto3 resources
# Connect to ec2Client


def lambda_handler(data, context):

    try :
        # Get instance id
        createdId = data['detail']['instance-id']
    except KeyError:
        # Print to log
        print("it was start of instance")
        # Get instance id
        createdId = data['InstanceId']

    print("0----------")
    print(createdId)

    # Check instance type
    ec2Client = boto3.client('ec2')
    created = ec2Client.describe_instances(InstanceIds = [createdId])['Reservations'][0]['Instances'][0]
    instanceType = created['InstanceType']
    userInstances = []
    isProtected = 'False'
    userEmail = ""
    userPolicy = ""
    # Check instance protection tag
    try :
        createdTags = formatTags(created['Tags'])
        print("1---------------")
        print(created)
        if 'Protected' in createdTags['Keys'] \
            and createdTags['Values'][ createdTags['Keys'].index('Protected') ] == 'True' :
            isProtected = 'True'
            print("3---------------" + isProtected)
        else:
            userData = findUserInTags(createdTags['Values'])
            userEmail = userData['email']
            userPolicy = userData['policy_arn']
            if userEmail != None :
                reservations = ec2Client.describe_instances()
                for reservation in reservations :
                    for instance in reservation['Instances']:
                        instanceTags = formatTags(instance['Tags'])
                        if instance['State']['Name'] != 'terminated' \
                            and instance['State']['Name'] != 'shutting-down' \
                            and userEmail in instanceTags['Values'] :
                            
                            userInstances.append(instance)
        print("5---------------")
        print(userInstances)

    # Terminate instance on error
    except (KeyError, NameError) :
        print("6---------------")
        print("Error")
        print("Termination instance: " + createdId)
        terminateInstances([createdId])
        print("Instance " + createdId +" terminated")
        return 0


    # Terminate all not protected and excess instances
    if ( len(userInstances) > 1 and isProtected != 'True' ) \
        or ( isProtected!= 'True' and userEmail == None ):

        print("6---------------"+"Termination instance: " + createdId)
        terminateInstances([createdId])
        print("7---------------"+"instance " + createdId +" terminated")
        return 0


def getUserFromDb(email) :

    # Get users for scenario
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    # Get user by createdId
    try :
        user = table.scan(
            FilterExpression = "email = :i",
            ExpressionAttributeValues = {
                ":i" : email
            }
        )['Items'][0]
        return { 
            'email' : user['email'],
            'policyArn': user['scenarios']['scenario3']['policy_arn'] 
        }
    except IndexError:
        return None

def findUserInTags(tagValues):
    usersList = []
    for tag in tagValues :
        user = getUserFromDb(tag)
        if user != None :
            usersList.append(user)
    if len(user) > 1 or len(user) == 0 :
        return None
    else :
        return usersList[0]

def terminateInstances(createdIds) :

    # Init EC2 client
    ec2 = boto3.client('ec2')

    # Remove instances
    response = ec2.terminate_instances(InstanceIds = createdIds)

    # Write to log response
    print("9---------------")
    print(response)

    # Return response
    return response

def formatTags(tagsDict):
    listTagsValues = []
    listTagsKeys = []
    for tag in tagsDict :
        listTagsKeys.append(tag['Key'])
        listTagsValues.append(tag['Value'])
    return {
        "Keys": listTagsKeys,
        "Values": listTagsValues
    }


def updatePersonalTerminatePolicy(policyArn) :
    iam = 
    