#!/bin/bash
# Read data from DynamoDB
data_base=($(aws dynamodb scan --table-name users --profile $1))
user_email=($(echo ${data_base[@]} | jq .Items[].email.S | tr -d '"'))
name=($(echo ${data_base[@]} | jq .Items[].email.S | tr -d '"' | cut -d @ -f 1))
secret_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario6.M.secret_key_user1.S | tr -d '"'))
access_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario6.M.access_key_user1.S | tr -d '"'))
username=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario6.M.username_user1.S | tr -d '"'))

# Creating backup files with aws credentials
if [ ! -f ~/.aws/config_bacup ]
  then
    cp ~/.aws/config ~/.aws/config_bacup
    cp ~/.aws/credentials ~/.aws/credentials_bacup
fi
echo "///////////////////////////////////"
echo "//         Scenario6             //"
echo "///////////////////////////////////"
# The passage of the 6th scenario by each user up to the creation of RDS inclusive
for ((i = 0; i < ${#user_email[@]}; i++))
    do
        echo "------------------------------------------------------------------------"
        echo ${username[i]}": "${user_email[i]}": "${access_key[i]}": "${secret_key[i]}
        echo "///////First way//////////"
        echo "***"
        echo "Configure profile user1_${name[i]}"
        echo "access_key: ${access_key[i]}"
        echo "secret_key: ${secret_key[i]}"
        aws configure set aws_access_key_id ${access_key[i]} --profile user${name[i]}_6_1
        aws configure set aws_secret_access_key ${secret_key[i]} --profile user${name[i]}_6_1
        aws configure set region eu-central-1 --profile user${name[i]}_6_1
        aws configure set output json --profile user${name[i]}_6_1
        echo "***"
        echo "Get list projects, access_key2, secret_key2"
        projects=($(aws codebuild list-projects --profile user${name[i]}_6_1 | jq .projects[] | grep ${name[i]} | tr -d '"' ))
        echo ${project}
        sc6_batch_get_projects=($(aws codebuild batch-get-projects --names ${projects} --profile user${name[i]}_6_1))
        access_key2=$(echo ${sc6_batch_get_projects[@]} | jq .projects[].environment.environmentVariables[0].value | tr -d '"')
        echo ${access_key2}
        secret_key2=$(echo ${sc6_batch_get_projects[@]} | jq .projects[].environment.environmentVariables[1].value | tr -d '"')
        echo ${secret_key2}
        echo "***"
        echo "Configure profile user2_${name[i]}"
        aws configure set aws_access_key_id ${access_key2} --profile user${i}_6_2
        aws configure set aws_secret_access_key ${secret_key2} --profile user${i}_6_2
        aws configure set region eu-central-1 --profile user${i}_6_2
        aws configure set output json --profile user${i}_6_2
        echo "***"
        echo "Create-db-snapshot user2_${name[i]}"
        describe_db_instances=($(aws rds describe-db-instances --profile user${i}_6_2))
        db_instance_identifier=($(echo ${describe_db_instances[@]} | jq .DBInstances[0].DBInstanceIdentifier | tr -d '"'))
        echo ${db_instance_identifier}
        aws rds create-db-snapshot --db-instance-identifier ${db_instance_identifier} --db-snapshot-identifier sc6-${i} --profile user${i}_6_2 &
        echo "***"
        # echo "Restore db-instance? (y/n)"
        # read y
        # if [ y != "y" ]
        #     then
        #     break
        # fi
        echo "Restore db-instance ${name[i]}-database from db-snapshot"
        describe_db_subnet_groups=($(aws rds describe-db-subnet-groups --profile user${i}_6_2))
        describe_security_groups=($(aws ec2 describe-security-groups --profile user${i}_6_2))
        db_subnet_group_name=($(echo ${describe_db_subnet_groups[@]} | jq .DBSubnetGroups[].DBSubnetGroupName | grep "cloud-goat-rds-testing-subnet-group" | tr -d '"'))
        echo "db_subnet_group_name; "${db_subnet_group_name}
        vpc_security_group_ids="sg-$(echo ${describe_security_groups[@]} | jq .SecurityGroups[] | jq '.GroupName'+'.GroupId' | grep "sc6-rds-psql" | tr -d '"' | cut -d - -f5)"
        #vpc_security_group_ids="sg-0779d800670b058f7"
        echo "vpc_security_group_ids; "${vpc_security_group_ids}
        aws rds restore-db-instance-from-db-snapshot --db-instance-identifier ${name[i]}-database --db-snapshot-identifier sc6-${i} --db-subnet-group-name ${db_subnet_group_name} --publicly-accessible --vpc-security-group-ids ${vpc_security_group_ids} --profile user${i}_6_2 &
        # echo "Next snapshot? (y/n)"
        # read y
        # if [ y != "y" ]
        #     then
        #     break
        # fi
        echo "///////Second way//////////"
        echo "Get secret key"
        name_private_key=($(aws ssm describe-parameters --profile user${name[i]}_6_1 | jq .Parameters[].Name | grep "sc6-ec2-private-key" | tr -d '"'))
        echo "name_private_key: "$name_private_key
        name_public_key=($(aws ssm describe-parameters --profile user${name[i]}_6_1 | jq .Parameters[].Name | grep "sc6-ec2-public-key" | tr -d '"'))
        echo "name_public_key: "$name_public_key
        public_key=$(aws ssm get-parameter --name $name_public_key --profile user${name[i]}_6_1 | jq .Parameter.Value | tr -d '"')
        echo "public_key: "$public_key
        echo -e $public_key > ./sc6/user${name[i]}_6_1_key.pub
        private_key=$(aws ssm get-parameter --name $name_private_key --profile  user${name[i]}_6_1 | jq .Parameter.Value | tr -d '"')
        echo "private_key: "$private_key
        echo -e $private_key > ./sc6/user${name[i]}_6_1_key
        chmod 400 ./sc6/user${name[i]}_6_1_key
        public_ip=($(aws ec2 describe-instances --profile user${name[i]}_6_1 | jq .Reservations[].Instances[] | jq '.PublicIpAddress'+'.KeyName' | tr -d '"' | grep "sc6-ec2-key-pair" | sed 's/sc6-ec2-key-pair//' | cut -d - -f1))
        echo "public_ip: "$public_ip
        #ssh -i ./sc6/user${name[i]}_6_1_key ubuntu@$public_ip "sudo apt update && sudo apt install awscli -y"

        echo "------------------------------------------------------------------------"
    done