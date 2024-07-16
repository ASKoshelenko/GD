import json, boto3, time
import logging

#Create own looger and set log display level 
logger = logging.getLogger()                        
logger.setLevel(logging.INFO)

# Initialize boto3 resources
# Connect to ec2Client
def lambda_handler(data, context):

    try :
        # Get instance id
        createdId = data['detail']['instance-id']
    except KeyError:
        # Print to log
        logger.exception("it was start of instance")
       
        # Get instance id
        createdId = data['InstanceId']

    logger.info("0----------")
    logger.info(createdId)

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
        logger.info("1---------------")
        logger.info(createdTags)
        if "Protected" in createdTags['Keys'] :
            logger.info("2 try ")
            protectedValue = createdTags['Values'][ createdTags['Keys'].index('Protected') ]
            if protectedValue == 'True' :
                isProtected = 'True'
                logger.info(f"3--------------- {isProtected}")
        else:
            userData = findUserInTags(createdTags['Values'])
            logger.info("4")
            logger.info(userData)
            if userData != None :
                userEmail = userData['email']
                reservations = (ec2Client.describe_instances())['Reservations']
                logger.info(reservations)
                for reservation in reservations :
                    for instance in reservation['Instances']:
                        instanceTags = formatTags(instance['Tags'])
                        if instance['State']['Name'] != 'terminated' \
                            and instance['State']['Name'] != 'shutting-down' \
                            and userEmail in instanceTags['Values'] :
                            
                            userInstances.append(instance)
        logger.info("5---------------")
        logger.info(userInstances)

    # Terminate instance on error
    except Exception:
        logger.info("6---------------") 
        logger.info("Error")
        logger.exception("e.args")
        logger.info("Termination instance: %s", createdId)
        terminateInstances([createdId])
        logger.exception(f"Instance {createdId} terminated" )   
        return 0


    # Terminate all not protected and excess instances
    if ( len(userInstances) > 1 and isProtected != 'True' ) \
        or ( isProtected!= 'True' and userEmail == "" ):

        logger.info("6--------------- Termination instance: %s", createdId)
        terminateInstances([createdId])
        logger.info(f"7--------------- instance {createdId} terminated")  

        return 0
    elif userEmail != "" :
        logger.info(f"user {userEmail} creates first instance")

        updatePersonalTerminatePolicy(userData['policyArn'], createdId, userData['username'])



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
            'policyArn': user['scenarios']['scenario3']['policy_arn'],
            'username' : user['scenarios']['scenario3']['username']
        }
    except IndexError:
        logger.exception("IndexError in getUserFromDb ")
        return None

def findUserInTags(tagValues):
    usersList = []
    for tag in tagValues :
        logger.info("process %s", tag)
        user = getUserFromDb(tag)
        if user != None :
            usersList.append(user)
    if len(usersList) > 1 or len(usersList) == 0 :
        return None
    else :
        logger.info(usersList[0])
        return usersList[0]

def terminateInstances(createdIds) :

    # Init EC2 client
    ec2 = boto3.client('ec2')

    # Remove instances
    response = ec2.terminate_instances(InstanceIds = createdIds)

    # Write to log response
    logger.info("9---------------")
    logger.info(response)

    # Return response
    logger.info(response)
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


def updatePersonalTerminatePolicy(policyArn, createdId, userName) :
    iamClient = boto3.client('iam')
    iam = boto3.resource('iam')
    policy = iam.Policy(policyArn)
    version = policy.default_version
    
    policyJson = version.document
    policyJson['Statement'][0]['Resource'] = ['arn:aws:ec2:eu-central-1:839606382402:instance/'+ createdId]
    
    for version in policy.versions.all():
        if version.version_id != policy.default_version.version_id:
            iamClient.delete_policy_version(PolicyArn = version.arn, VersionId = version.version_id)
    
    response = iamClient.detach_user_policy(
        UserName=userName,
        PolicyArn=policyArn
    )

    response = iamClient.delete_policy(
        PolicyArn=policyArn
    )

    newPolicy = iamClient.create_policy(
      PolicyName='ec2TerminateInstanceWithTag',
      PolicyDocument=json.dumps(policyJson)
    )
    logger.info(newPolicy)

    attachment = iamClient.attach_user_policy(
        UserName=userName,
        PolicyArn=newPolicy['Policy']['Arn']
    )
    logger.info(attachment)
    