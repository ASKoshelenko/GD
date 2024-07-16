from operator import itemgetter
import re 
import json
import boto3
from telebot import TeleBot
import logging
import traceback


TOKEN = 'empty' # The one you got from @BotFather while creating the bot
bot = TeleBot(TOKEN)


logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')

emailRegex = "^[a-z0-9]+[\._]?[a-z0-9]+[@]\w+[.]\w{2,5}$"



def lambda_handler(event, context):
    print(event)
    data = json.loads(event["body"])
    chat_id = data["message"]["chat"]["id"]
    try:
        message = str(data["message"]["text"])
    except KeyError:
        bot.send_message(chat_id, "Please print /Login <your @email.com")
        return 1
        
    splitted_message = message.split(" ")

    if len(splitted_message) > 2:
        bot.send_message(chat_id,"warning, expected command /login <your@email.com")
        return
    command = splitted_message[0]
    
    if (command == "/login"):
        try:
            email = splitted_message[1].lower()        
            if (validate_email(email)):
                validated = check_user_email(table, email)
                if (validated != None): 
                    if (validated and validated['telegramid'] == 'empty'):
                        update_chat_id(table, validated['userid'], chat_id)
                        bot.send_message(chat_id, "Your email is registered for aws game day challenge " + email)
                        return "table updated"
                    else:
                        bot.send_message(chat_id, "this email was already registered")
                        return
                else:
                    bot.send_message(chat_id, "your email was not registered for aws game day challenge,please contact admin")
                    return
            else:
                bot.send_message(chat_id,"warning, expected command /login <your@email.com")
        except IndexError:
            bot.send_message(chat_id, "Please print /login <your @email.com")
    else:
        bot.send_message(chat_id, "your message should start your command as /login <your@email.com>") 



def validate_email(email):
    if (re.search(emailRegex,email)):
        return True
    return False 

def check_user_email(table, email): 
    try:
        # Get user by instance_id
        item = table.scan(
            FilterExpression="email = :e",
            ExpressionAttributeValues={
                ":e": email
            },
            ProjectionExpression='email, \
                userid, \
                telegramid \
            '
        )['Items'][0]
        return item
    except IndexError:
        logger.info(f"There is no user with target {email}")
        return None
        
def update_chat_id(table, user_id, chat_id):
    try:
        item = table.update_item(
            Key={
                'userid': user_id
            },
            UpdateExpression="set telegramid = :t",
            ExpressionAttributeValues={
                ':t': str(chat_id),
            },
            ReturnValues="UPDATED_NEW"
        )
        return item
    except IndexError:
        logger.exception(f"User not exists")
        return None

def validate_email(email):
    if (re.search(emailRegex,email)):
        return True
    return False 


      

