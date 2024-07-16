#!/bin/bash
aws dynamodb scan --table-name users --profile $1 > ./db.json
user_email=($(cat db.json | jq .Items[].email.S | tr -d '"'))
name=($(cat db.json | jq .Items[].email.S | tr -d '"' | cut -d @ -f 1))
secret_key=($(cat db.json | jq .Items[].scenarios.M.scenario1.M.secret_key.S | tr -d '"'))
access_key=($(cat db.json | jq .Items[].scenarios.M.scenario1.M.access_key.S | tr -d '"'))
username=($(cat db.json | jq .Items[].scenarios.M.scenario1.M.username.S | tr -d '"'))

if [ ! -f ~/.aws/config_bacup ]
  then
    cp ~/.aws/config ~/.aws/config_bacup
    cp ~/.aws/credentials ~/.aws/credentials_bacup
fi

for ((i = 0; i < ${#user_email[@]}; i++))
    do
        echo ${username[i]}": "${user_email[i]}": "${access_key[i]}": "${secret_key[i]}
        aws configure set aws_access_key_id ${access_key[i]} --profile user${i}
        aws configure set aws_secret_access_key ${secret_key[i]} --profile user${i}
        aws configure set region eu-central-1 --profile user${i}
        aws configure set output json --profile user${i}
        echo "list-attached-user-policies"
        aws iam list-attached-user-policies --user-name ${username[i]} --profile user${i}
        echo "list-policy-versions"
        aws iam list-policy-versions --policy-arn arn:aws:iam::839606382402:policy/policy_scenario1_${name[i]} --profile user${i}
        echo "get-policy-version"
        aws iam get-policy-version --policy-arn arn:aws:iam::839606382402:policy/policy_scenario1_${name[i]} --version-id v3 --profile user${i}
        echo "set-default-policy-version"
        aws iam set-default-policy-version --policy-arn arn:aws:iam::839606382402:policy/policy_scenario1_${name[i]} --version-id v3 --profile user${i}
        echo "list-policy-versions"
        aws iam list-policy-versions --policy-arn arn:aws:iam::839606382402:policy/policy_scenario1_${name[i]} --profile user${i}
        echo "set-default-policy-version"
        aws iam set-default-policy-version --policy-arn arn:aws:iam::839606382402:policy/policy_scenario1_${name[i]} --version-id v1 --profile $1
    done