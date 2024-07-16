#########################
## Count final results ##
#########################

import boto3
import csv
from tabulate import tabulate
import dateutil.parser

session = boto3.Session(
    aws_access_key_id='', # PUT VALID DATA
    aws_secret_access_key='', # OR ADD PARAMS IF YOU WISH :)
    region_name='eu-central-1'
)

EVENT_SCENARIOS = [1,2,3]

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
    scen3=[]
    scen2=[]
    scen1=[]
    for i in s:
        if i['scenarios']['count'] == EVENT_SCENARIOS[2]:
            scen3.append(i)
        if i['scenarios']['count'] == EVENT_SCENARIOS[1]:
            scen2.append(i)
        if i['scenarios']['count'] == EVENT_SCENARIOS[0]:
            scen1.append(i)
    sc3 = sorted(scen3, key=lambda x: list(x['notifications']['congratulations'].values())[0])
    sc2 = sorted(scen2, key=lambda x: list(x['notifications']['congratulations'].values())[0])
    sc1 = sorted(scen1, key=lambda x: list(x['notifications']['congratulations'].values())[0])
    sc3.extend(sc2)
    sc3.extend(sc1)
    time10= "2021-08-21T08:00:00Z"
    starttime = dateutil.parser.parse(time10)
    result = []
    for i in sc3:
        arr=[]
        arr.append(i["email"])
        arr.append(i['scenarios']['count'])
        endtime = dateutil.parser.parse(list(i['notifications']['congratulations'].values())[0])
        delta = endtime - starttime
        arr.append(str(delta))
        result.append(arr)
    return result


def output_to_file(res_list):
    headers = ["EMAIL", "SCENARIOS", "TIME"]
    output = tabulate(res_list,headers,tablefmt="fancy_grid")
    output.encode("utf-8")
    with open('results.txt', "w", encoding="utf-8") as f:
        f.write(output)
    return 0


def output_to_csv(res_list):
    headers = ["EMAIL", "SCENARIOS", "TIME"]
    with open('results.csv', "w", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        k=0
        for i in res_list:
            data = [str(res_list[k][0]), str(res_list[k][1]), str(res_list[k][2])]
            writer.writerow(data)
            k=k+1
    return 0


def result_bucket(bucket_name,awssession):
    s3=awssession.client('s3',region_name='eu-central-1')
    s3.create_bucket(Bucket=bucket_name,CreateBucketConfiguration={
        'LocationConstraint': 'eu-central-1',
    },)
    with open("results.txt", "rb") as f:
        s3.upload_fileobj(f, bucket_name, "results.txt")
    with open("results.csv", "rb") as f:
        s3.upload_fileobj(f, bucket_name, "results.csv")
    return 0


def main():
    res = search_congrat(get_users_data(session))
    output_to_file(res)
    output_to_csv(res)
    result_bucket('result-bucket-epmc-acm16', session)


if __name__ == "__main__":
    main()




