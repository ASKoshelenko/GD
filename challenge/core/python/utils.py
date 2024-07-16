from http import client
import imp
import json
import os
import random
import re
import string
import tempfile
import yaml
import boto3
import botocore
import requests

from boto3.dynamodb.conditions import Key, Attr
from core.python.python_terraform import VariableFiles, Terraform

EC2SecurityGroupEVENTS = ['CreateSecurityGroup']
RDSInstanceEVENTS = ['RestoreDBInstanceFromDBSnapshot']
RDSSnapshotsEVENTS = ['CreateDBSnapshot']
EC2SecurityGroupsNAME = 'SecurityGroups'
RDSInstancesNAME = 'DBInstances'
RDSSnapshotsNAME = 'DBSnapshots'

class PatchedVariableFiles(VariableFiles):
    def create(self, variables):
        with tempfile.NamedTemporaryFile(
                "w+t", suffix=".tfvars.json", delete=False
        ) as temp:
            self.files.append(temp)
            temp.write(json.dumps(variables))
            file_name = temp.name

        return file_name


class PatchedTerraform(Terraform):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.temp_var_files = PatchedVariableFiles()


def check_own_ip_address():
    res = requests.get("https://ifconfig.co/json")
    if res.status_code != 200:
        return None

    data = res.json()
    return data.get("ip")


def create_dir_if_nonexistent(base_path, dir_name):
    dir_path = os.path.join(base_path, dir_name)

    try:
        os.mkdir(dir_path)
    except FileExistsError:
        pass

    return dir_path


def create_or_update_yaml_file(file_path, new_data):
    if not file_path or not new_data:
        return

    merged_data = dict()

    if os.path.exists(file_path):
        with open(file_path, "r") as file:
            data_loaded_from_file = yaml.safe_load(file.read())

        if not data_loaded_from_file:
            data_loaded_from_file = list()

        for loaded_section in data_loaded_from_file:
            for loaded_key, loaded_value in loaded_section.items():
                if loaded_key not in new_data.keys():
                    merged_data[loaded_key] = loaded_value

    merged_data.update(new_data)

    converted_data = list()

    for key, value in merged_data.items():
        converted_data.append({key: value})

    with open(file_path, "w") as file:
        file.write(yaml.safe_dump(converted_data))


def dirs_at_location(base_path, names_only=False):
    dirs = list()
    for filesystem_object in os.scandir(base_path):
        if filesystem_object.is_dir():
            if names_only:
                dirs.append(os.path.basename(filesystem_object.path))
            else:
                dirs.append(filesystem_object.path)
    return dirs


def display_terraform_step_error(step, retcode, stdout, stderr):
    print(
        f"\n[cloudgoat] Error while running `{step}`."
        f"\n    exit code: {retcode}"
        f"\n    stdout: {stdout}"
        f"\n    stderr: {stderr}\n"
    )


def extract_cgid_from_dir_name(dir_name):
    match = re.match(r"(?:.*)\_(cgid(?:[a-z0-9]){10})", dir_name)
    if match:
        return match.group(1)
    return None


def find_scenario_dir(scenarios_dir, dir_name):
    for dir_path in dirs_at_location(scenarios_dir):
        if os.path.basename(dir_path) == dir_name:
            return dir_path
    return None


def find_scenario_instance_dir(base_dir, scenario_name, username=""):
    for dir_path in dirs_at_location(base_dir):
        dir_match = re.findall(
            r"(.*)\_cgid(?:[a-z0-9]){10}$", os.path.basename(dir_path)
        )
        if dir_match and dir_match[0] == scenario_name:
            return dir_path
    return None


def generate_cgid(username=""):
    if username is not "":
        return username
    else:
        return "cgid" + "".join(
            random.choice(string.ascii_lowercase + string.digits) for x in
            range(10)
        )


def ip_address_or_range_is_valid(text):
    if not text:
        return False

    if text.count("/") == 0:
        return False
    elif text.count("/") == 1:
        octets, subnet = text.split("/")
    else:
        return False

    if octets.startswith(".") or octets.endswith("."):
        return False
    elif not len(octets.split(".")) == 4:
        return False

    for octet in octets.split("."):
        if not octet.isdigit():
            return False
        if len(octet) > 1 and octet.startswith("0"):
            return False
        if not (0 <= int(octet) <= 255):
            return False

    if not subnet.isdigit():
        return False
    elif not (0 <= int(subnet) <= 32):
        return False

    return True


def load_and_validate_whitelist(whitelist_path):
    whitelisted_ips = list()

    with open(whitelist_path, "r") as whitelist_file:
        lines = whitelist_file.read().split("\n")

    # Save the original line numbers alongside the lines.
    lines = zip(range(1, len(lines) + 1), lines)
    # Remove comments.
    lines = filter(lambda line: not line[1].strip().startswith("#"), lines)
    # Remove empty lines.
    lines = filter(lambda line: bool(line[1]), lines)
    # Listify it to avoid consuming the generator during iteration (for `len`).
    lines = list(lines)

    for iteration_number, original_line_tuple in enumerate(lines, 1):
        original_line_number, line = original_line_tuple
        if line.strip() == "":
            continue

        is_valid = ip_address_or_range_is_valid(line.strip())

        if not is_valid:
            print(
                f"\nWhitelist line {original_line_number} is invalid:"
                f"\n    {line[:150]}\n"
                f"\nPlease repair the line and try again. IP addresses may use CIDR"
                f" notation. For example:"
                f"\n    127.0.0.1"
                f"\n    127.0.0.1/32"
            )
            return None

        whitelisted_ips.append(line.strip())

    if not whitelisted_ips:
        print(
            f"No IP addresses or ranges found. Add IP addresses in CIDR notation, or"
            f' delete the whitelist.txt file and try "config whitelist".'
        )
        return None

    return whitelisted_ips


def load_data_from_yaml_file(file_path, key):
    if not file_path or not key:
        return

    with open(file_path, "r") as file:
        yaml_data = yaml.safe_load(file.read())

    if yaml_data:
        for section in yaml_data:
            if key in section.keys():
                return section[key]

    return None


def normalize_scenario_name(scenario_name_or_path):
    if not scenario_name_or_path:
        return scenario_name_or_path

    scenario_instance_name_match = re.findall(
        r".*?(\w+)_cgid(?:[a-z0-9]){10}.*", scenario_name_or_path
    )
    if scenario_instance_name_match:
        return scenario_instance_name_match[0]

    if scenario_name_or_path.count(os.path.sep) == 0:
        return scenario_name_or_path

    fully_split_path = scenario_name_or_path.split(os.path.sep)

    if "scenarios" in fully_split_path:
        index = fully_split_path.index("scenarios")
        relative_path = os.path.sep.join(fully_split_path[index: index + 2])
        return os.path.basename(relative_path.strip(os.path.sep))
    else:
        return os.path.basename(scenario_name_or_path.strip(os.path.sep))


def disable_protection(profile, tag_scenario):
    session = boto3.Session(profile_name=profile)
    ec2client = session.client('ec2')
    Reservations = ec2client.describe_instances(
        Filters=[
            {
                'Name': 'tag:Scenario',
                'Values': [
                    str(tag_scenario)
                ]
            }
        ]
    )['Reservations']
    for instance in Reservations:
        for i in instance['Instances']:
            Instance_Id = i['InstanceId']
            # Get ApiTermination attribute
            apiTermination = ec2client.describe_instance_attribute(
                Attribute='disableApiTermination',
                InstanceId=Instance_Id
            )['DisableApiTermination']['Value']
            print('apiTermination of Instance (' + Instance_Id + '): ' + str(
                apiTermination))
            if apiTermination == True:
                ec2client.modify_instance_attribute(
                    InstanceId=Instance_Id,
                    DisableApiTermination={
                        'Value': False
                    }
                )
                print('Instance (' + Instance_Id + ') protection is disabled')


# Clear trash
def clearScenario3UserResources(profile):
    # Connect to aws
    session = boto3.Session(profile_name=profile)

    # Get users for scenario
    dynamodb = session.resource('dynamodb')
    table = dynamodb.Table('users')

    # Init ec2 boto client
    ec2Client = session.client('ec2')

    # Get all key pairs
    key_pairs = ec2Client.describe_key_pairs()['KeyPairs']

    # Connect to cloudtrail by boto3
    trail = session.client('cloudtrail')

    # Init map for targets
    targets = {}

    # Process key pairs
    for key in key_pairs:
        # Get instance events
        events = trail.lookup_events(
            LookupAttributes=[
                {
                    'AttributeKey': 'ResourceName',
                    'AttributeValue': key['KeyName']
                }
            ]
        )
        pageExists = True
        # Read while pages exist
        while pageExists:
            # Find instance creating log
            try:
                for event in events['Events']:

                    if event['EventName'] == 'CreateKeyPair' or event[
                        'EventName'] == 'ImportKeyPair':

                        print('found possible creating event')
                        print('key:' + key['KeyName'])

                        # If errorCode key not exists current item is target
                        try:
                            json.loads(event['CloudTrailEvent'])['errorCode']
                            continue

                        except KeyError:
                            if event['Username'] not in targets:
                                targets[event['Username']] = {}
                                targets[event['Username']]['Keys'] = []
                            targets[event['Username']]['Keys'].append(
                                key['KeyName'])
                            break

                # break wh loop if find creating event
                if key['KeyName'] in targets.values():
                    break

                # Set next token to page
                nextToken = events['NextToken']

                # Get instance events
                events = trail.lookup_events(
                    LookupAttributes=[
                        {
                            'AttributeKey': 'ResourceName',
                            'AttributeValue': key['KeyName']
                        }
                    ],
                    NextToken=nextToken
                )
            except KeyError:
                break

    # Get primary keys list
    userid = getUserIdListFromCollection(table.scan(
        ProjectionExpression='userid'
    )['Items'])

    # Read actual ec2 instance
    ec2 = session.resource('ec2')
    instances = ec2.instances.filter(
        Filters=[
            {
                'Name': 'instance-state-name',
                'Values': [
                    'pending',
                    'running',
                    'stopping',
                    'stopped'
                ]
            }
        ]
    ).all()

    targetInstances = []
    # Process instances
    for instance in instances:
        instance = processInstanceTags(instance)
        if instance != None:
            tags = formatTags(instance.tags)
            for value in tags['Values']:
                if value in userid:
                    targetInstances.append(instance.instance_id)
    if len(targetInstances) > 0:
        terminateInstances(targetInstances, session)

    for username in targets:
        user = getUserFromDbScenario3(username, session)
        if user != None:
            removeKeyPairs(targets[username]['Keys'], session)


def getUserFromDbScenario3(username, session):
    # Get users for scenario
    dynamodb = session.resource('dynamodb')
    table = dynamodb.Table('users')

    # Get user by instance_id
    try:
        user = table.scan(
            FilterExpression="scenarios.scenario3.username = :i",
            ExpressionAttributeValues={
                ":i": username
            }
        )['Items'][0]

        # If user exists return user item
        return user

    except IndexError:
        return None


def removeKeyPairs(key_pairs, session):
    # Init EC2 client
    ec2 = session.client('ec2')

    # Inir responces list
    responses = []

    # Remove key pairs from ec2
    for key in key_pairs:
        responses.append(ec2.delete_key_pair(KeyName=key))

    # Print responces to log
    print(responses)

    return responses


def terminateInstances(instance_ids, session):
    # Init EC2 client
    ec2 = session.client('ec2')

    # Remove instances
    response = ec2.terminate_instances(InstanceIds=instance_ids)

    # Write to log response
    print(response)

    # Return response
    return response


def formatTags(tagsDict):
    listTagsValues = []
    listTagsKeys = []
    for tag in tagsDict:
        listTagsKeys.append(tag['Key'])
        listTagsValues.append(tag['Value'])
    return {
        "Keys": listTagsKeys,
        "Values": listTagsValues
    }


def getUserIdListFromCollection(userid):
    userIdList = []
    for user in userid:
        userIdList.append(user['userid'])
    return userIdList


def processInstanceTags(instance):
    # If protected return None
    if instance.tags != None:
        # Find protected tag
        for tag in instance.tags:
            if tag['Key'] == 'Protected' and tag["Value"] == 'True':
                return None
        return instance

    # If not portected return instance id
    else:
        return None


def clearScenario6UserResources(profile):
    # Connect to aws
    session = boto3.Session(profile_name=profile)

    # Init rds boto client
    rdsClient = session.client('rds')

    # Init ec2 boto client
    ec2Client = session.client('ec2')

    # Find and remove all snapshots
    dbSnapshots = getResourceIds(
        rdsClient.describe_db_snapshots()[RDSSnapshotsNAME],
        'DBSnapshotIdentifier')
    print(dbSnapshots)
    dbSnapshotsTarget = getCreatedResources(session, dbSnapshots,
                                            RDSSnapshotsEVENTS,
                                            RDSSnapshotsNAME)
    print(dbSnapshotsTarget)
    processTargets(dbSnapshotsTarget, RDSSnapshotsNAME, session)

    # Find and delete RDS instances
    rdsInstances = getResourceIds(
        rdsClient.describe_db_instances()[RDSInstancesNAME],
        'DBInstanceIdentifier')
    print(rdsInstances)
    rdsInstancesTarget = getCreatedResources(session, rdsInstances,
                                             RDSInstanceEVENTS,
                                             RDSInstancesNAME)
    print(rdsInstancesTarget)
    processTargets(rdsInstancesTarget, RDSInstancesNAME, session)

    # Find and delete ec2 security groups
    ec2SGs = getResourceIds(
        ec2Client.describe_security_groups()[EC2SecurityGroupsNAME], 'GroupId')
    print(ec2SGs)
    ec2SGsTarget = getCreatedResources(session, ec2SGs, EC2SecurityGroupEVENTS,
                                       EC2SecurityGroupsNAME)
    print(ec2SGsTarget)
    processTargets(ec2SGsTarget, EC2SecurityGroupsNAME, session)

    return

def clearScenario8UserResources(profile):
    # Connect to aws
    session = boto3.Session(profile_name=profile)

    ecrClient = session.client('ecr')
    dynamodb = session.resource('dynamodb')
    table = dynamodb.Table('users')

    response = table.scan(ProjectionExpression='scenarios.scenario8.ecr_repository_name')['Items']

    for item in response:
        try:
          reponame = item['scenarios']['scenario8']['ecr_repository_name']
        except KeyError:
          print('ECR repo not exists in DB')
        try:
          print('Delete ECR repo:', reponame)
          ecrClient.delete_repository(repositoryName=reponame,force=True)
        except:
          print('ECR deletion not succesfull: ', reponame)


    return

def getUserFromDbScenario6(username, session):
    # Get users for scenario
    dynamodb = session.resource('dynamodb')
    table = dynamodb.Table('users')

    # Get user by instance_id
    try:
        user = table.scan(
            FilterExpression=Attr("scenarios.scenario6.username_user1").eq(
                username) | Attr("scenarios.scenario6.username_user2").eq(
                username),
            ProjectionExpression="scenarios.scenario6.username_user1, scenarios.scenario6.username_user2"
        )['Items'][0]

        # If user exists return user item
        return user

    except IndexError:
        return None


def getCreatedResources(session, resourceList, eventNames, targetType):
    # Connect to cloudtrail by boto3
    trail = session.client('cloudtrail')

    # Init map for targets
    targetList = {}

    # Process key pairs
    for resource in resourceList:
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
        while pageExists:
            # Find instance creating log
            try:
                for event in events['Events']:

                    if event['EventName'] in eventNames:

                        print('found possible creating event')

                        # If errorCode key not exists current item is target
                        try:
                            json.loads(event['CloudTrailEvent'])['errorCode']
                            continue

                        except KeyError:
                            if event['Username'] not in targetList:
                                targetList[event['Username']] = {}
                                targetList[event['Username']][targetType] = []
                            targetList[event['Username']][targetType].append(
                                resource)
                            break

                # break while loop if find creating event
                if resource in targetList.values():
                    break

                # Set next token to page
                nextToken = events['NextToken']

                # Get instance events
                events = trail.lookup_events(
                    LookupAttributes=[
                        {
                            'AttributeKey': 'ResourceName',
                            'AttributeValue': resource
                        }
                    ],
                    NextToken=nextToken
                )
            except KeyError:
                break
    return targetList


def getResourceIds(resourceList, idName):
    # Get onlfy resource ids list from RDS client responce

    targetList = []
    for resource in resourceList:
        targetList.append(resource[idName])
    return targetList


def deleteEC2SecurityGroups(session, sgIdsList):
    # Remove security griups list of SG ids

    ec2Client = session.client('ec2')
    try:
        if len(sgIdsList) != 0:
            for sgId in sgIdsList[EC2SecurityGroupsNAME]:
                print(ec2Client.delete_security_group(GroupId=sgId))
        else:
            print("SG list is empty")
    except botocore.exceptions.ClientError:
        print(
            "An error occurred (DependencyViolation) when calling the DeleteSecurityGroup operation: resource " + sgId + " has a dependent object")


def deleteDBSnapshots(session, dbSnapshotIds):
    # Remove db snapshots by list of snapshots ids

    rdsClient = session.client('rds')
    if len(dbSnapshotIds) != 0:
        for dbSnapshotId in dbSnapshotIds[RDSSnapshotsNAME]:
            print(dbSnapshotId)
            print(
                rdsClient.delete_db_snapshot(DBSnapshotIdentifier=dbSnapshotId))
    else:
        print("DBSnapshots list is empty")


def deleteRDSInstances(session, rdsInstanceIds):
    # Remove db instances by list of RDS instances ids

    rdsClient = session.client('rds')
    if len(rdsInstanceIds) != 0:
        for rdsInstanceId in rdsInstanceIds[RDSInstancesNAME]:
            print(
                rdsClient.delete_db_instance(DBInstanceIdentifier=rdsInstanceId,
                                             SkipFinalSnapshot=True))
            # print(rdsClient.delete_db_instance_automated_backup(DBInstanceIdentifier = rdsInstanceId))
    else:
        print("DBInstances list is empty")

def processTargets(targetList, resourceType, session):
    # If user from target exists in Ddb delete his resources

    for target in targetList:
        user = getUserFromDbScenario6(target, session)
        print(user)
        if user != None:
            if resourceType == EC2SecurityGroupsNAME:
                deleteEC2SecurityGroups(session, targetList[target])
            elif resourceType == RDSSnapshotsNAME:
                deleteDBSnapshots(session, targetList[target])
            elif resourceType == RDSInstancesNAME:
                deleteRDSInstances(session, targetList[target])
            else:
                print("Wrong type of next items")
                print(targetList[target])

# def deleteSNSTopics(profile) :
#     # Connect to aws
#     session = boto3.Session(profile_name=profile)

#     dynamodb = session.resource('dynamodb')
#     table = dynamodb.Table('users')
#     sns = session.client('sns')
#     try :
#         users = table.scan()['Items']
#     except:
#         print("table 'users' not exists")
#     for user in users :
#         try :
#             print(sns.delete_topic(
#                 TopicArn = user['topic_arn']
#             ))
#         except KeyError as e:
#             print(e)
#             continue
def createS3remote(profile, region, bucket):
    print("createS3remote start")
    session = boto3.Session(profile_name=profile,region_name=region)
    client = session.client('s3',region_name=region)
    location ={'LocationConstraint':region}
    response = client.create_bucket(
    ACL ='private',
    # authenticated-read',
    Bucket = bucket,
    CreateBucketConfiguration=location
       
    )
    client = session.client('s3')
    s3 = session.resource('s3')
    versioning = s3.BucketVersioning(bucket)
    versioning.enable()

def deleteS3remote(profile):
    session = boto3.Session(profile_name=profile)
    s3 = session.resource('s3')
    s3_bucket = s3.Bucket('aws-game-day-tfstate-bucket')
    bucket_versioning = s3.BucketVersioning('aws-game-day-tfstate-bucket')
    if bucket_versioning.status == 'Enabled':
        s3_bucket.object_versions.delete()
    else:
        s3_bucket.objects.all().delete()
    try:
        client = session.client('s3')
        response = client.delete_bucket(
            Bucket='aws-game-day-tfstate-bucket'
        )
        return "deleted"
    except: 
        return None    

def clearScenario7UserLambda(profile):
    session = boto3.Session(profile_name=profile)
    client = session.client('lambda',region_name='eu-central-1')
    # Get lambda fucntion
    list_function = (
        client.get_paginator('list_functions')
        .paginate()
        .build_full_result()
        )['Functions']
    # Get users for scenario
    dynamodb = session.resource('dynamodb')
    table = dynamodb.Table('users')
    # Get table items
    userids = table.scan(
        ProjectionExpression='userid'
    )['Items']
    list_role_arn = []
    # Get lambda manager role arn
    for userid in userids:
        item = table.get_item(
            Key={"userid": userid['userid']},
            ProjectionExpression='\
            scenarios.scenario7.lambdaExecutioneRolearn',        
        )['Item']['scenarios']['scenario7']['lambdaExecutioneRolearn']
        list_role_arn.append(item)
    function_name = []
    # Get lambda name for delete
    for role in list_function:
        if role["Role"] in list_role_arn:
            function_name.append(role["FunctionName"])
    # Delete all lambda
    for name in function_name:
        client.delete_function(FunctionName=name)

def detachUserPolicy(profile):
    session = boto3.Session(profile_name=profile)
     # Get users for scenario
    dynamodb = session.resource('dynamodb')
    table = dynamodb.Table('users')
    # Get table items
    userids = table.scan(
        ProjectionExpression='userid'
    )['Items']
    iam = session.client('iam')
    # Get lambda manager role arn
    for userid in userids:
        item = table.get_item(
            Key={"userid": userid['userid']},
            ProjectionExpression='\
            scenarios.scenario7.username',
        )['Item']['scenarios']['scenario7']
        list_attached_policy = iam.list_attached_user_policies(
        UserName = item['username'])['AttachedPolicies']
        for policy in list_attached_policy:
            iam.detach_user_policy(
            UserName = item['username'],
            PolicyArn = policy['PolicyArn']
            )
