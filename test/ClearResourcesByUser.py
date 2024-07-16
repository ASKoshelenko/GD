import json, boto3

def lambda_handler(data, context):
    username = "kerrigan"
    # Connect to cloudtrail by boto3
    trail = boto3.client('cloudtrail')
    
    # Collect and process all events by instance profile
    events = trail.lookup_events(
    LookupAttributes=[
        {
            'AttributeKey': 'Username',
            'AttributeValue': username
        }
    ])
    target=[]
    for event in events['Events'] :
        try :
            json.loads(event['CloudTrailEvent'])['errorCode']
        except KeyError:
            if event['ReadOnly'] == "false" :
                target.append(event)
    print(target)
    resources = []
    for t in target :
        for resource in t['Resources'] :
            resources.append( {resource['ResourceType'] : resource['ResourceName']})
    print(resources)
        
    