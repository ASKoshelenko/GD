import boto3, json
from boto3.dynamodb.conditions import Key, Attr

EC2SecurityGroupEVENTS = ['CreateSecurityGroup']
RDSInstanceEVENTS = ['RestoreDBInstanceFromDBSnapshot']
RDSSnapshotsNAMEEVENTS = ['CreateDBSnapshot']
EC2SecurityGroupsNAME = 'SecurityGroups'
RDSInstancesNAME = 'DBInstances'
RDSSnapshotsNAME = 'DBSnapshots'

def lambda_handler(data, data2):

    # Init rds boto client
    rdsClient = boto3.client('rds')
    
    # Init ec2 boto client
    ec2Client = boto3.client('ec2')
    
    # Find and remove all snapshots
    dbSnapshots = getResourceIds(rdsClient.describe_db_snapshots()[RDSSnapshotsNAME], 'DBSnapshotIdentifier')
    print(dbSnapshots)
    dbSnapshotsTarget = getCreatedResources(dbSnapshots, RDSSnapshotsNAMEEVENTS, RDSSnapshotsNAME)
    print(dbSnapshotsTarget)
    processTargets(dbSnapshotsTarget,RDSSnapshotsNAME)
        
    # Find and delete RDS instances
    rdsInstances = getResourceIds(rdsClient.describe_db_instances()[RDSInstancesNAME], 'DBInstanceIdentifier')
    print(rdsInstances)
    rdsInstancesTarget = getCreatedResources(rdsInstances, RDSInstanceEVENTS, RDSInstancesNAME)
    print(rdsInstancesTarget)    
    processTargets(rdsInstancesTarget,RDSInstancesNAME)
    
    # Find and delete ec2 security groups
    ec2SGs = getResourceIds(ec2Client.describe_security_groups()[EC2SecurityGroupsNAME], 'GroupId')
    print(ec2SGs)
    ec2SGsTarget = getCreatedResources(ec2SGs, EC2SecurityGroupEVENTS, EC2SecurityGroupsNAME)
    print(ec2SGsTarget)    
    processTargets(ec2SGsTarget,EC2SecurityGroupsNAME)
    
    return
    
def getUserFromDb(username) :
    
    # Connect to aws
    # session = boto3.Session(profile_name=profile)
    
    # Get users for scenario
    # dynamodb = session.resource('dynamodb')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    # Get user by instance_id
    try : 
        user = table.scan(
            FilterExpression = Attr("scenarios.scenario6.username_user1").eq(username) | Attr("scenarios.scenario6.username_user2").eq(username),
            ProjectionExpression = "scenarios.scenario6.username_user1, scenarios.scenario6.username_user2"
        )['Items'][0]

        # If user exists return user item
        return user

    except IndexError :
        return None
        
def getCreatedResources(resourceList, eventNames, targetType) :
    
    # Connect to cloudtrail by boto3
    trail = boto3.client('cloudtrail')

    # Init map for targets
    targetList = {}

    # Process key pairs
    for resource in resourceList :
        # Get instance events
        events = trail.lookup_events(
            LookupAttributes=[
                {
                    'AttributeKey': 'ResourceName',
                    'AttributeValue': resource
                }
            ]
        )
        pageExists = True
        # Read while pages exist
        while pageExists :
            # Find instance creating log
            try :
                for event in events['Events'] : 
                    
                    if event['EventName'] in eventNames:
                        
                        print('found possible creating event')
                        
                        # If errorCode key not exists current item is target
                        try :
                            json.loads(event['CloudTrailEvent'])['errorCode']
                            continue
    
                        except KeyError :
                                if  event['Username'] not in targetList :
                                    targetList[event['Username']] = {}
                                    targetList[event['Username']][targetType] = [] 
                                targetList[event['Username']][targetType].append(resource)
                                break
                
                # break while loop if find creating event        
                if resource in targetList.values() :
                    break
                
                # Set next token to page
                nextToken = events['NextToken']
                
                # Get instance events
                events = trail.lookup_events(
                    LookupAttributes = [
                        {
                            'AttributeKey': 'ResourceName',
                            'AttributeValue': resource
                        }
                    ],
                    NextToken = nextToken
                )
            except KeyError :
                break
    return targetList
            
def getResourceIds(resourceList, idName) :
    # Get only resource ids list from RDS client responce
    targetList = []
    for resource in resourceList :
        targetList.append(resource[idName])
    return targetList

def deleteEC2SecurityGroupsNAME(sgIdsList) :
        
    # Connect to aws
    # session = boto3.Session(profile_name=profile)
    
    # Init EC2 client
    # ec2 = session.client('ec2')
    ec2Client = boto3.client('ec2')
    
    if len(sgIdsList) !=0 :
        for sgId in sgIdsList :
            print(sgId)
            # print(ec2Client.delete_security_group(GroupId=sgId))
    else :
        print("SG list is empty")

def deleteDBSnapshots(dbSnapshotIds) :
    # Remove db snapshots by list of snapshots ids

    rdsClient = boto3.client('rds')
    if len(dbSnapshotIds) != 0 :
        for dbSnapshotId in dbSnapshotIds :
            print(rdsClient.delete_db_snapshot(DBSnapshotIdentifier = dbSnapshotId))
    else :
        print("DBSnapshots list is empty")

def deleteRDSInstancesNAME(rdsInstanceIds) :
    # Remove db instances by list of RDS instances ids
    
    rdsClient = boto3.client('rds')
    if len(rdsInstanceIds) != 0 :
        for rdsInstanceId in rdsInstanceIds :
            print(rdsClient.delete_db_instance(DBInstanceIdentifier = rdsInstanceId))
            #print(rdsClient.delete_db_instance_automated_backup(DBInstanceIdentifier = rdsInstanceId))
    else :
        print("DBInstances list is empty")

def processTargets(targetList, resourceType):
    # If user from target exists in Ddb delete his resources
    
    for target in targetList :
        user = getUserFromDb(target)
        print(user)
        if user != None :
            if resourceType == EC2SecurityGroupsNAME    : deleteEC2SecurityGroupsNAME(targetList[target])
            elif resourceType == RDSSnapshotsNAME       : deleteDBSnapshots(targetList[target])
            elif resourceType == RDSInstancesNAME       : deleteRDSInstancesNAME(targetList[target])
            else : 
                print("Wrong type of next items")
                print(targetList[target])
            
