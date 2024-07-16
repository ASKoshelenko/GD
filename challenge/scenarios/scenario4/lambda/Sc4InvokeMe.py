import boto3
import json
import base64
import logging

# Create own logger and set log display level
logger = logging.getLogger()
logger.setLevel(logging.INFO)


# Hello it is the simplest lambda, invoke me if you can
def invoke_function(data, context):
    lambda_client = boto3.client('lambda')
    response = lambda_client.invoke(
        FunctionName="Sc4FinCheck",
        Payload=json.dumps(data),
        LogType='Tail'
    )
    logger.info(base64.b64decode(
        response['ResponseMetadata']['HTTPHeaders']['x-amz-log-result']))
    
    results = json.loads(response['Payload'].read())
    return results
