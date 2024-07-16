import json
import boto3
from boto3.dynamodb.conditions import Attr
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')

table = dynamodb.Table('targetdb')

def handle(event):
  body = event.get('body')
  if body is None:
    return 400, "missing body"

  if 'id=' and 'firstname=' not in body:
    return 400, "missing id or firstname or another default parameter"

  return 200, "OK" 

def handler(event, context):
  statusCode, responseBody = handle(event)
  if search_id(event['id']):
    update_item(event)
  else:
    add_item(event)
    
  return {
    "isBase64Encoded": False,
    "statusCode": statusCode,
    "headers": {},
    "multiValueHeaders": {},
    "body": json.dumps({'message': responseBody})
  }

def search_id(id):
  response = table.scan(FilterExpression=Attr('id').eq(id))
  if response['Count'] == 0:
    return False
  else:
    return True

def update_item(item):
  table.update_item(
    Key={'id': item['id']},
    ExpressionAttributeNames={
        '#fn': 'firstname',
        '#ln': 'lastname',
        '#cn': 'cardnumber',
        '#am': 'amount'
        },
    ExpressionAttributeValues={
        ':fn': item['firstname'],
        ':ln': item['lastname'],
        ':cn': item['cardnumber'],
        ':am': Decimal(item['amount'])
        },
    UpdateExpression='SET #fn = :fn, #ln = :ln, #cn = :cn, #am = :am'
  )  

def add_item(item):
  table.put_item(
  Item = {
    'id': item['id'], 
    'firstname': item['firstname'],
    'lastname': item['lastname'],
    'cardnumber': item['cardnumber'],
    'amount': Decimal(item['amount'])
   }
)
