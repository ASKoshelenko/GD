import boto3
import json
import datetime

# get readable datetime from json
def convert_timestamp(item_date_object):
    if isinstance(item_date_object, (datetime.date, datetime.datetime)):
        return item_date_object.strftime("%c")
        
# main function
def lambda_handler(event, context):
    conn = boto3.client('s3')
    
    # Create result list
    list = []
    
    # Process all objects from bucket 
    for item in conn.list_objects(Bucket='simplejspwebapp')['Contents']:
        res = dict()
        res["Name"] = item["Key"]
        res["Date"] = json.dumps(item["LastModified"], default=convert_timestamp)
        res["Owner"]= item["Owner"]["ID"]
        list.append(res)
     
    print(list) # Print results for log
    return list