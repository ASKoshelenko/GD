import json
import boto3
import logging
import time
from boto3.dynamodb.conditions import Key, Attr

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    {
      "scenario_name": "scenario1",
      "user_ids": [
        "bohdan_syniuk"
      ]
    }
    """
    scenario_id = event["scenario_name"]
    template_name = "congratulations"
    placeholders = {"ScenarioName": scenario_id}
    user_ids_json = event["user_ids"]

    lambda_client = boto3.client("lambda")
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table("users")

    logger.info(f"Processing scenario: {scenario_id}, User IDs: {user_ids_json}")

    all_emails_sent = True
 
    for userid in user_ids_json:
        try:
            if "@" in userid:
                raise ValueError("Invalid userid: '@' symbol not allowed")

            response = table.get_item(
                Key={"userid": userid},
                ProjectionExpression="userid, scenarios.#scenario, email",
                ExpressionAttributeNames={"#scenario": scenario_id},
            )
            item = response.get('Item')
            
            if not item:
                logger.error(f"No data found for userid {userid}")
                all_emails_sent = False
                continue

            logger.info(f"User ID: {userid}, working on email: {item['email']} - Sending congratulation email")

            lambda_client.invoke(
                FunctionName="SendingNotifications",
                InvocationType="Event",
                Payload=json.dumps({
                    "email": item["email"],
                    "is_resend": True,
                    "placeholders": placeholders,
                    "template_name": template_name,
                    "userid": item["userid"],
                })
            )

            time.sleep(1)
        except ValueError as e:
            logger.error(f"Error: {e}")
            all_emails_sent = False
        except KeyError:
            logger.exception("Key not Exists")
            all_emails_sent = False
        except Exception as e:
            logger.exception(f"General Exception for User ID: {userid} - {str(e)}")
            all_emails_sent = False

    if all_emails_sent:
        return {
            'statusCode': 200,
            'body': json.dumps('All emails sent successfully.')
        }
    else:
        return {
            'statusCode': 500,
            'body': json.dumps('Some emails failed to send.')
        }
