import boto3
import json

def lambda_handler(event, context):

    # check eventName
    if event['eventName'] == 'GetObject':

        # get username from event
        AccsessKey = event['userIdentity']['accessKeyId']
        print(AccsessKey)
        outFromLogs = getlogs(AccsessKey)
        return outFromLogs

def getlogs(key):

    # connect to cloudwatch by boto3
    client = boto3.client('logs')

    # get all logs for user
    response = client.filter_log_events(
        logGroupName = 'CloudTrail/s3check',
        filterPattern = key
    )
    logList = []
    for log in response['events']:
        msg=json.loads(log['message'])
        logList.append(msg['userIdentity']['principalId'])
        logList.append(msg['userIdentity']['accessKeyId'])
        logList.append(msg['userIdentity']['sessionContext']['sessionIssuer']['userName'])
    return logList