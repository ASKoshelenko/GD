import json
import boto3
from jinja2 import Template

def lambda_handler(event, context):
    template_name = 'template.html'
    template_path = '/tmp/'+ template_name
    bucket_name = 'email-templates-challenge'
    s3 = boto3.client('s3')
    s3.download_file(bucket_name, template_name, template_path)
    
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    
    for item in table.scan()['Items']:
        email=item['email']
        name=email.split('_')[0]
        
        sc1_access_key = item['scenarios']['scenario1']['access_key']
        sc1_secret_key = item['scenarios']['scenario1']['secret_key']
        sc1_username = item['scenarios']['scenario1']['username']
        
            
        sc2_access_key = item['scenarios']['scenario2']['access_key']
        sc2_secret_key = item['scenarios']['scenario2']['secret_key']
        sc2_username = item['scenarios']['scenario2']['username']
        sc2_target_ip = item['scenarios']['scenario2']['target_ip']
        sc2_target_lambda = item['scenarios']['scenario2']['target_lambda']
        
        sc3_access_key = item['scenarios']['scenario3']['access_key']
        sc3_secret_key = item['scenarios']['scenario3']['secret_key']
        sc3_username = item['scenarios']['scenario3']['username']
        sc3_target_id = item['scenarios']['scenario3']['target_id']
        
        sc4_access_key = item['scenarios']['scenario4']['access_key']
        sc4_secret_key = item['scenarios']['scenario4']['secret_key']
        sc4_username = item['scenarios']['scenario4']['username']
        sc4_target_key = item['scenarios']['scenario4']['target_key']
        
        sc5_access_key = item['scenarios']['scenario5']['access_key_user1']
        sc5_secret_key = item['scenarios']['scenario5']['secret_key_user1']
        sc5_username = item['scenarios']['scenario5']['username_user1']
        sc5_target_lambda = item['scenarios']['scenario5']['target_lambda']
        
        sc6_access_key = item['scenarios']['scenario6']['access_key_user1']
        sc6_secret_key = item['scenarios']['scenario6']['secret_key_user1']
        sc6_username = item['scenarios']['scenario6']['username_user1']
        sc6_target_lambda = item['scenarios']['scenario6']['target_lambda']
        
        with open(template_path) as file_:
            template = Template(file_.read())
        outputText = template.render(email=email,
                                    name=name,
                                    sc1_access_key=sc1_access_key, 
                                    sc1_secret_key=sc1_secret_key, 
                                    sc1_username=sc1_username, 
                                    sc2_access_key=sc2_access_key, 
                                    sc2_secret_key=sc2_secret_key, 
                                    sc2_username=sc2_username, 
                                    sc2_target_ip=sc2_target_ip, 
                                    sc2_target_lambda=sc2_target_lambda, 
                                    sc3_access_key=sc3_access_key,
                                    sc3_secret_key = sc3_secret_key,
                                    sc3_username = sc3_username,
                                    sc3_target_id = sc3_target_id,
                                    sc4_access_key = sc4_access_key,
                                    sc4_secret_key = sc4_secret_key,
                                    sc4_username = sc4_username,
                                    sc4_target_key = sc4_target_key,
                                    sc5_access_key = sc5_access_key,
                                    sc5_secret_key = sc5_secret_key,
                                    sc5_username = sc5_username,
                                    sc5_target_lambda = sc5_target_lambda,
                                    sc6_access_key = sc6_access_key,
                                    sc6_secret_key = sc6_secret_key,
                                    sc6_username = sc6_username,
                                    sc6_target_lambda = sc6_target_lambda
            )

        file_name = email+ ".html"
        s3.put_object(Body=outputText, Bucket=bucket_name, Key=file_name)