import json
import boto3

def lambda_handler(event, context):
    username= "Anatolii_Hromov_CLI"
    iam_client = boto3.client('iam')
    createdId = "i-036283c854aeb6f4d"
    iam = boto3.resource('iam')
    policy = iam.Policy('arn:aws:iam::839606382402:policy/ec2TerminateInstanceWithTag')
    version = policy.default_version
    
    policyJson = version.document
    policyJson['Statement'][0]['Resource'] = ['arn:aws:ec2:eu-central-1:839606382402:instance/'+ createdId]
    print(policyJson)
    
    for version in policy.versions.all():
        if version.version_id != policy.default_version.version_id:
            iam_client.delete_policy_version(PolicyArn = version.arn, VersionId = version.version_id)
    
    response = iam_client.detach_user_policy(
        UserName='Anatolii_Hromov_CLI',
        PolicyArn='arn:aws:iam::839606382402:policy/ec2TerminateInstanceWithTag'
    )
    
    response = iam_client.delete_policy(
        PolicyArn='arn:aws:iam::839606382402:policy/ec2TerminateInstanceWithTag'
    )

    print(response)
    response = iam_client.create_policy(
      PolicyName='ec2TerminateInstanceWithTag',
      PolicyDocument=json.dumps(policyJson)
    )
    print(response)
    
    response = client.attach_user_policy(
        UserName=username
        PolicyArn=responce['Policy']['Arn']
    )