import boto3
import json
import datetime

#Get readable datetime from json
def convert_timestamp(item_date_object):
    if isinstance(item_date_object, (datetime.date, datetime.datetime)):
        return item_date_object.strftime("%c")

#Main function - process all objects from bucket 
def lambda_handler(event, context):
  s3 = boto3.client('s3')
  results = s3.list_objects(Bucket="flamingofiles")
  output = ''

  for file in results['Contents']:
    output += file['Key'] + ", owner: " + file['Owner']['ID'] + ", modified at: " + json.dumps(file['LastModified'], default=convert_timestamp) + "\n"
  return(output)
  