#!/bin/bash
# Read data from DynamoDB
data_base=($(aws dynamodb scan --table-name users --profile $1))
user_email=($(echo ${data_base[@]} | jq .Items[].email.S | tr -d '"'))
name=($(echo ${data_base[@]} | jq .Items[].email.S | tr -d '"' | cut -d @ -f 1))
secret_key1=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario5.M.secret_key_user1.S | tr -d '"'))
access_key1=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario5.M.access_key_user1.S | tr -d '"'))
username1=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario5.M.username_user1.S | tr -d '"'))
secret_key2=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario5.M.secret_key_user2.S | tr -d '"'))
access_key2=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario5.M.access_key_user2.S | tr -d '"'))
username2=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario5.M.username_user2.S | tr -d '"'))

# Creating backup files with aws credentials
if [ ! -f ~/.aws/config_bacup ]
  then
    cp ~/.aws/config ~/.aws/config_bacup
    cp ~/.aws/credentials ~/.aws/credentials_bacup
fi
#before continuing, forward the ssh-key ~/.aws/sc5_key.pub using $dns_name and $elb_key
echo "Is the ssh key forwarded? (y/n)"
        read y
        if [ y != "y" ]
            then
            break
        fi
public_ip=($(aws ec2 describe-instances --profile $1 | jq .Reservations[].Instances[] | jq '.PublicIpAddress'+'.KeyName' | tr -d '"' | grep "sc5-ec2-key-pair" | sed 's/sc5-ec2-key-pair//' | cut -d - -f1))
ssh -i ~/.ssh/sc5_key ubuntu@${public_ip} 'sudo apt-get install awscli'
sleep 15s

# The passage of the 6th scenario by each user up to the creation of RDS inclusive
echo "///////////////////////////////////"
echo "//         Scenario5             //"
echo "///////////////////////////////////"
echo "public_ip: "${public_ip}
for ((i = 0; i < ${#user_email[@]}; i++))
    do

        echo "------------------------------------------------------------------------"
        echo ${name[i]}": "${user_email[i]}": "${username1[i]}": "${username2[i]}
        echo "///////First way//////////"
        echo "***"
        echo "Configure profile user5_1${name[i]}"
        echo "access_key1: ${access_key1[i]}"
        echo "secret_key1: ${secret_key1[i]}"
        aws configure set aws_access_key_id ${access_key1[i]} --profile user5_1${name[i]}
        aws configure set aws_secret_access_key ${secret_key1[i]} --profile user5_1${name[i]}
        aws configure set region eu-central-1 --profile user5_1${name[i]}
        aws configure set output json --profile user5_1${name[i]}
        echo "***"
        echo "Get 1-st public ssh key"
        bucket5_1=($(aws s3 ls --profile user5_1${name[i]} | grep "sc5-logs-s3-bucket" | cut -d ' ' -f3))
        echo "bucket5_1: "$bucket5_1

        logs_file=($(aws s3 ls s3://${bucket5_1} --recursive --profile user5_1${name[i]} | grep "555555555555" | cut -d ' ' -f9))
        echo "logs_file: "$logs_file

        aws s3 cp s3://${bucket5_1}/${logs_file} ./sc5/sc5_logs_user5_1${name[i]}.log --profile user5_1${name[i]}
        elb_key=($(cat ./sc5/sc5_logs_user5_1${name[i]}.log | cut -d '/' -f6 | head -n1 | cut -d ' ' -f1))
        echo "elb_key: " $elb_key
        dns_name=($(aws elbv2 describe-load-balancers --profile user5_1${name[i]} | jq .LoadBalancers[].DNSName | grep "sc5-lb-" | tr -d '"'))
        echo "dns_name: " $dns_name


        #before continuing, forward the ssh-key ~/.aws/sc5_key.pub using $dns_name and $elb_key
        #
        bucket2=($(aws s3 ls --profile user5_1${name[i]} | grep "sc5-secret-s3-bucket" | cut -d ' ' -f3))
        echo "bucket2: "$bucket2
        address=($(aws rds describe-db-instances --region eu-central-1 --profile user5_1${name[0]} | jq .DBInstances[].Endpoint.Address | grep "sc5-rds-instance" | tr -d '"'))
        echo "elb address: "$address
        db_name="SecurityChallenge"
        ssh -i ~/.ssh/sc5_key ubuntu@${public_ip} "aws s3 cp s3://${bucket2}/db.txt ./tmp/db.txt"
        scp -i ~/.ssh/sc5_key ubuntu@${public_ip}:~/tmp/db.txt ./sc5/user5_1${name[i]}.txt
        scp -i ~/.ssh/sc5_key ubuntu@${public_ip}:~/sc5/user5_1${name[i]}.txt ./sc5/user5_1${name[i]}.txt
        username_db=($(cat ./sc5/user5_1${name[i]}.txt | grep "Username" | cut -d ' ' -f2))
        echo "username_db: "$username_db
        password=($(cat ./sc5/user5_1${name[i]}.txt | grep "Password" | cut -d ' ' -f2))
        echo "password: "$password
        ssh -i ~/.ssh/sc5_key ubuntu@${public_ip} "pg_dump postgresql://${username_db}:${password}@${address}:5432/${db_name} > db.txt"
        scp -i ~/.ssh/sc5_key ubuntu@${public_ip}:~/db.txt ./sc5/${name[i]}.txt
        key_string=($(cat ./sc5/${name[i]}.txt | grep ${name[i]}))
        completion_key=${key_string[1]}
        echo "completion_key: " ${completion_key}
        echo "user name: "${name[i]}
        aws lambda invoke --cli-binary-format raw-in-base64-out --function-name sc5_complete_${name[i]} --payload "{\"key\": \"${completion_key}\"}" --profile user5_1${name[i]} response.json

        echo "///////Second way//////////"
        echo "access_key2: ${access_key2[i]}"
        echo "secret_key2: ${secret_key2[i]}"
        aws configure set aws_access_key_id ${access_key2[i]} --profile user5_2${name[i]}
        aws configure set aws_secret_access_key ${secret_key2[i]} --profile user5_2${name[i]}
        aws configure set region eu-central-1 --profile user5_2${name[i]}
        aws configure set output json --profile user5_2${name[i]}
        echo "***"
        echo "Get 2-th public ssh key"
        bucket5_2=($(aws s3 ls --profile user5_2${name[i]} | grep "sc5-keystore-s3-bucket" | cut -d ' ' -f3))
        echo "bucket5_2: "$bucket5_2
        list_security_file=($(aws s3 ls s3://${bucket5_2} --recursive --profile user5_2${name[i]}))
        private_file=$(echo ${list_security_file[@]} | cut -d ' ' -f4)
        echo "private_file: "$private_file
        public_file=$(echo ${list_security_file[@]} | cut -d ' ' -f8)
        echo "public_file: "$public_file
        aws s3 cp s3://${bucket5_2}/${private_file} ./sc5/${private_file} --profile user5_2${name[i]}
        chmod 600 ./sc5/${private_file}
        aws s3 cp s3://${bucket5_2}/${public_file} ./sc5/${public_file} --profile user5_2${name[i]}

        public_ip_2=($(aws ec2 describe-instances --profile user5_2${name[i]} | jq .Reservations[].Instances[] | jq '.PublicIpAddress'+'.KeyName' | tr -d '"' | grep "sc5-ec2-key-pair" | sed 's/sc5-ec2-key-pair//' | cut -d - -f1))
        echo "------------------------------------------------------------------------"
    done