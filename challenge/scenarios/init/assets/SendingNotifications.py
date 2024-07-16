import smtplib
import re
import boto3
import json
import os
import time
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from jinja2 import Template
from botocore.vendored import requests
import logging

# import requests

# Create own looger and set log display level
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table_users = dynamodb.Table('users')


# Get SMTP credentials from SSM
def get_credentials():
    client = boto3.client('ssm')
    response = client.get_parameters(
        Names=[
            'SMTP-email',
            'SMTP-password'
        ],
        WithDecryption=True
    )
    dict = {"login": response['Parameters'][0]['Value'],
            "password": response['Parameters'][1]['Value']}
    return dict


# Get template from lambda


def get_template(template_name):
    template_name = template_name + ".html"
    s3 = boto3.client('s3')

    body = s3.get_object(
        Bucket='templates-hackaton-notify',
        Key=template_name
    )['Body'].read().decode("utf-8")

    return body


# template processing


def template_processed(template_name, scenario, userid):
    try:
        notifications = table_users.get_item(
            Key={'userid': userid},
            AttributesToGet=['notifications']
        )['Item']['notifications']
    except KeyError:
        logger.exception('User not exists')
        return True

    try:
        return scenario in notifications[template_name]
    except KeyError:
        return False


def put_template(html_body, template_name, username):
    """
    Put html to s3 buckets
    """
    s3 = boto3.client('s3')
    template_name = template_name + ".html"
    s3.put_object(
        Body=html_body,
        Bucket='prepared-user-templates-hackathon',
        Key=f"Prepared templates/{username}/{template_name}"
    )


# get a username from his email, adding placeholders to the template  and sending emails


def lambda_handler(event, context):
    template_name = event['template_name']
    scenario = event['placeholders']['ScenarioName']
    userId = event['userid']
    email = event['email']
    credential = get_credentials()
    login = credential['login']
    password = credential['password']
    is_resend = event.get('is_resend', False)
    if template_processed(template_name, scenario, userId) and not is_resend:
        logger.info(f"Already sent to {userId}")
    else:
        if not 'name' in event['placeholders']:
            a = (''.join([i for i in email if not i.isdigit()])).split(
                '@')[0].split('_')
            for i in range(len(a)):
                a[i] = a[i].capitalize()
            event['placeholders']['name'] = ' '.join(a)
        to = email
        template = get_template(template_name)
        subject_str = template['subject'] if 'subject' in template else 'AWS SECURITY CHALLENGE'
        subject = Template(subject_str)
        html_str = template

        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject.render(event['placeholders'])
        msg['From'] = 'Auto_EPMC-ACM_AWS_Game_Day@epam.com'
        msg['To'] = to
        html = Template(html_str)
        rendered_html = html.render(event['placeholders'])
        put_template(html_body=rendered_html, template_name=template_name,
                     username=event['placeholders']['name'])
        msg.attach(MIMEText(rendered_html, 'html'))
        mailserver = smtplib.SMTP('smtp.office365.com', 587)
        mailserver.ehlo()
        mailserver.starttls()
        mailserver.login(login, password)
        mailserver.sendmail(login, to, msg.as_string())
        mailserver.quit()

        # writing information about sending a message to the database

        update = table_users.update_item(
            Key={
                'userid': userId
            },
            UpdateExpression='SET notifications.#template_name = :newItem',
            ExpressionAttributeNames={
                "#template_name": template_name
            },
            ExpressionAttributeValues={
                ':newItem': {
                    scenario: datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')
                }
            },
            ReturnValues="UPDATED_NEW"
        )
        logger.info(update)
