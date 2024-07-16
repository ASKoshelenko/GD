from array import array
from cgitb import text
from email import message
from operator import truediv
from telebot import TeleBot
import json
TOKEN = 'empty' # The one you got from @BotFather while creating the bot
WBH_URL = 'SuperEmpty' # URL of your choice
bot = TeleBot(TOKEN)
bot.set_webhook(url = WBH_URL, allowed_updates = ["message"], drop_pending_updates = True) # Setting the Webhook.

#bot.delete_webhook(WBH_URL)


