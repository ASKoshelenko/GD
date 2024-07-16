import json
import boto3
import time

def lambda_handler(event, context):
    # TODO implement
    client = boto3.client('s3')
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('users')
    scenrio_list = ['scenario1', 'scenario2', 'scenario3', 'scenario4', 'scenario5', 'scenario6']
    
    list_prod = []
    list_rd = []
    
    for item in table.scan()['Items']:
        score = int(item['scenarios']['scenario1']['passed']) + int(item['scenarios']['scenario2']['passed']) + int(item['scenarios']['scenario3']['passed']) + int(item['scenarios']['scenario4']['passed']) + int(item['scenarios']['scenario5']['passed']) + int(item['scenarios']['scenario6']['passed']) 
        percentage = score * 100 // 6
        if (percentage == 100):
            percentage = 99
        progress_bar = f'<div class="progress" style="height: 40px;"><div class="progress-bar bg-success h-100" role="progressbar" style="width: {percentage}%;" aria-valuenow="{percentage}" aria-valuemin="0" aria-valuemax="100"><div style="margin-top: 10px;"><h6>{percentage}%</h6></div></div></div>'
        
        names = []
        for i in scenrio_list:
            email = item['email']
            if (email=="Mykola_Hrechaniuk@epam.com"):
                email="Harikrishna_Valugonda@epam.com"
            if item['scenarios'][i]['passed']:
                names.append('<img src="icons/yes.png" style="height: 40px;" alt="Passed!"')
            else:
                names.append('<img src="icons/no.png" style="height: 40px;" alt="Failed:("')
        
        d = {   'email':email, 
                'scenario1': names[0],
                'scenario2': names[1],
                'scenario3': names[2],
                'scenario4': names[3],
                'scenario5': names[4],
                'scenario6': names[5],
                'score': progress_bar
        }

        if (item['category'] == 'prod'):
            list_prod.append(d)
        elif (item['category'] == 'rd'):
            list_rd.append(d)
    
    list_prod_2 = sorted(list_prod, key = lambda i: i['score'], reverse = True)
    list_rd_2 = sorted(list_rd, key = lambda i: i['score'], reverse = True) 
    time1 = time.strftime('%l:%M%p %Z')
    
    file_text_prod = "var prod = \n" + str(list_prod_2) + "; \n$(function () {\n    $('#prod').bootstrapTable({\n        data: prod\n    });\n});"
    file_text_rd = "var rd = \n" + str(list_rd_2) + "; \n$(function () {\n    $('#rd').bootstrapTable({\n        data: rd\n    });\n});"
    file_time = 'document.getElementById("time").innerHTML = "' + time1 + '";'
    
    client.put_object(Body=file_text_prod, Bucket='challenge-dashboard', Key='js/prod.js')
    client.put_object(Body=file_text_rd, Bucket='challenge-dashboard', Key='js/rd.js')
    client.put_object(Body=file_time, Bucket='challenge-dashboard', Key='js/time.js')
    #return list