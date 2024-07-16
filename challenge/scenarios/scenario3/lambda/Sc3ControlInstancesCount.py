import json
import boto3
import os
import logging

# Create own logger and set log display level 
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(data, context):
    try:
        # Get instance id
        created_id = data['detail']['instance-id']
    except KeyError:
        # Print to log
        logger.exception("it was start of instance ")
        # Get instance id
        created_id = data['InstanceId']

    logger.info("0----------")
    logger.info(created_id)

    # Check instance type
    ec2_client = boto3.client('ec2')
    created = ec2_client.describe_instances(
        InstanceIds=[created_id])['Reservations'][0]['Instances'][0]
    instance_type = created['InstanceType']
    user_instances = []
    is_protected = 'False'
    user_email = ""
    user_policy = ""
    # Check instance protection tag
    try:
        created_tags = format_tags(created['Tags'])
        logger.info("1---------------")
        logger.info(created_tags)
        if "Protected" in created_tags['Keys']:
            logger.info("2 try ")
            # print("2 try ")
            protected_value = created_tags['Values'][
                created_tags['Keys'].index('Protected')]
            if protected_value == 'True':
                is_protected = 'True'
                logger.info(f"3--------------- {is_protected} ")
        else:
            user_data = find_user_in_tags(created_tags['Values'])
            logger.info("4")
            logger.info(user_data)
            if user_data != None:
                user_email = user_data['email']
                user_id = user_data['userid']
                reservations = (ec2_client.describe_instances())['Reservations']
                logger.info(reservations)
                # print(reservations)
                for reservation in reservations:
                    for instance in reservation['Instances']:
                        if instance['State']['Name'] != 'terminated' \
                                and instance['State']['Name'] != 'shutting-down' \
                                and 'Tags' in instance.keys():

                            instance_tags = format_tags(instance['Tags'])
                            if user_id in instance_tags['Values']:
                                user_instances.append(instance)

        logger.info("5---------------")
        logger.info(user_instances)

    # Terminate instance on error
    except Exception as e:
        logger.info(
            "6---------------")
        # we may have to delete half of the prints, because logger.exception 
        # outputs a more detailed description of the error 
        logger.exception("Error")
        logger.exception("e.args")
        logger.exception(f"Termination instance: {created_id}")
        terminate_instances([created_id])
        logger.info("6---------------")
        return 0

    # Terminate all not protected and excess instances
    if ( len(user_instances) > 1 and is_protected != 'True' ) \
        or ( is_protected != 'True' and user_email == "" ):

        logger.info(f"6--------------- Termination instance:  {created_id} ")
        terminate_instances([created_id])
        logger.info(f"7--------------- instance {created_id} terminated")
        return 0
    elif user_email != "":
        logger.info(f"user {user_email} creates first instance")
        update_personal_terminate_policy(user_data['policy_arn'], created_id,
                                         user_data['username'])


def get_user_from_db(key):
    # Init scenario id variable
    scenario_id = os.environ['ScenarioName']

    # Get users for scenario
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')

    # Get user by created_id
    try:
        user = table.get_item(
            Key={"userid": key },
            ProjectionExpression='\
                userid, \
                email, \
                scenarios.#scenario.policy_arn, \
                scenarios.#scenario.username \
            ',
            ExpressionAttributeNames={
                "#scenario": scenario_id
            }
        )['Item']
        return {
            'userid': user['userid'],
            'email': user['email'],
            'policy_arn': user['scenarios'][scenario_id]['policy_arn'],
            'username': user['scenarios'][scenario_id]['username']
        }
    except KeyError:
        logger.exception("KeyError ")
        return None


def find_user_in_tags(tag_values):
    users_list = []
    for tag in tag_values:
        logger.info(f"process {tag}")
        user = get_user_from_db(tag)
        if user:
            users_list.append(user)
    if len(users_list) > 1 or len(users_list) == 0:
        return None
    else:
        return users_list[0]


def terminate_instances(created_ids):
    # Init EC2 client
    ec2 = boto3.client('ec2')

    # Remove instances
    response = ec2.terminate_instances(InstanceIds=created_ids)

    # Write to log response
    logger.info("9---------------")
    logger.info(response)

    # Return response
    logger.info(response)
    return response


def format_tags(tags_dict):
    list_tags_values = []
    list_tags_keys = []
    for tag in tags_dict:
        list_tags_keys.append(tag['Key'])
        list_tags_values.append(tag['Value'])
    return {
        "Keys": list_tags_keys,
        "Values": list_tags_values
    }


def update_personal_terminate_policy(policy_arn, created_id, user_name):
    iam_client = boto3.client('iam')
    iam = boto3.resource('iam')
    policy = iam.Policy(policy_arn)
    version = policy.default_version

    policy_json = version.document
    policy_json['Statement'][0]['Resource'] = [
        'arn:aws:ec2:eu-central-1:*:instance/' + created_id]

    for version in policy.versions.all():
        if version.version_id != policy.default_version.version_id:
            iam_client.delete_policy_version(PolicyArn=version.arn,
                                             VersionId=version.version_id)

    response = iam_client.detach_user_policy(
        UserName=user_name,
        PolicyArn=policy_arn
    )

    response = iam_client.delete_policy(
        PolicyArn=policy_arn
    )

    new_policy = iam_client.create_policy(
        PolicyName=policy.policy_name,
        PolicyDocument=json.dumps(policy_json)
    )
    logger.info(new_policy)

    attachment = iam_client.attach_user_policy(
        UserName=user_name,
        PolicyArn=new_policy['Policy']['Arn']
    )
    logger.info(attachment)
