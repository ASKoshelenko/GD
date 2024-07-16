#########################
## Count final results ##
#########################
import boto3
import csv
import os
from tabulate import tabulate
import dateutil.parser
import io
import datetime

session = boto3.Session(
    region_name='eu-central-1'
)

EVENT_SCENARIOS = [1,2,3,4]

def get_users_data(awssession):
    dynamodb = awssession.resource('dynamodb',region_name='eu-central-1')
    table = dynamodb.Table('users')
    resp = table.scan()
    tokens = []
    for i in resp['Items']:
        if i['category'] == 'student':
            tokens.append(i)
    j = 0
    congrat = []
    for i in tokens:
        if 'congratulations' in tokens[j]['notifications']:
            congrat.append(tokens[j])
        j = j+1
    return congrat


def search_congrat(results):
    count_res = []
    for i in results:
        count = 0
        k = []
        for j in list(i['scenarios']):
            if i['scenarios'][j]['passed'] == True:
                count = count + 1
            k = i
            k['scenarios']['count'] = count
        count_res.append(k)


    s = sorted(count_res, key=lambda x: (x['scenarios']['count'], list(x['notifications']['congratulations'].values())[0]),reverse=True)
    scen4=[]
    scen3=[]
    scen2=[]
    scen1=[]
    for i in s:
        if i['scenarios']['count'] == EVENT_SCENARIOS[3]:
            scen4.append(i)
        if i['scenarios']['count'] == EVENT_SCENARIOS[2]:
            scen3.append(i)
        if i['scenarios']['count'] == EVENT_SCENARIOS[1]:
            scen2.append(i)
        if i['scenarios']['count'] == EVENT_SCENARIOS[0]:
            scen1.append(i)
    sc4 = sorted(scen4, key=lambda x: list(x['notifications']['congratulations'].values())[0])
    sc3 = sorted(scen3, key=lambda x: list(x['notifications']['congratulations'].values())[0])
    sc2 = sorted(scen2, key=lambda x: list(x['notifications']['congratulations'].values())[0])
    sc1 = sorted(scen1, key=lambda x: list(x['notifications']['congratulations'].values())[0])
    sc4.extend(sc3)
    sc4.extend(sc2)
    sc4.extend(sc1)
    time10 = os.environ['StartTime']
    starttime = dateutil.parser.parse(time10)
    result = []
    for i in sc4:
        arr=[]
        arr.append(i["email"])
        arr.append(i["username"])
        arr.append(i['scenarios']['count'])
        endtime = dateutil.parser.parse(list(i['notifications']['congratulations'].values())[0])
        delta = endtime - starttime
        arr.append(str(delta))
        result.append(arr)
    return result


def output_to_file(res_list):
    headers = ["EMAIL","USERNAME", "SCENARIOS", "TIME"]
    output = tabulate(res_list,headers,tablefmt="fancy_grid")
    output.encode("utf-8")
    return output


def output_to_csv(res_list):
    headers = ["EMAIL","USERNAME", "SCENARIOS", "TIME"]
    # Concatenate headers and data
    csv_content = []
    csv_content.append(headers)
    csv_content.extend(res_list)
    
    # Create a CSV file in memory
    csv_buffer = io.StringIO()
    csv_writer = csv.writer(csv_buffer)
    csv_writer.writerows(csv_content)
    return csv_buffer.getvalue()


def result_bucket(bucket_name, awssession, file_contents, file_key):
    s3=awssession.client('s3',region_name='eu-central-1')
    s3.put_object(Body=file_contents, Bucket=bucket_name, Key=file_key)
    return 0


def lambda_handler(event, lambda_context):
    res = search_congrat(get_users_data(session))
    result = output_to_file(res)
    result_csv = output_to_csv(res)
    timestamp_format = '%Y_%m_%d_%H'
    timestamp = datetime.datetime.now().strftime(timestamp_format)
    file_key = f'result{timestamp}.txt'
    file_key_cvs = f'result{timestamp}.csv'
    result_bucket_name = os.environ["BucketName"]
    result_bucket(result_bucket_name, session, result_csv, file_key_cvs)
    result_bucket(result_bucket_name, session, result, file_key)

if __name__ == "__main__":
    main()

