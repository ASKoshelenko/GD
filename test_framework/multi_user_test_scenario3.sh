#!/bin/bash
#aws dynamodb scan --table-name users --profile $1 > ./db.json
data_base=($(aws dynamodb scan --table-name users --profile $1))
user_email=($(echo ${data_base[@]} | jq .Items[].email.S | tr -d '"'))
name=($(echo ${data_base[@]} | jq .Items[].email.S | tr -d '"' | cut -d @ -f 1))
secret_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario3.M.secret_key.S | tr -d '"'))
access_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario3.M.access_key.S | tr -d '"'))
username=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario3.M.username.S | tr -d '"'))
target_id=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario3.M.target_id.S | tr -d '"'))

if [ ! -f ~/.aws/config_bacup ]
  then
    cp ~/.aws/config ~/.aws/config_bacup
    cp ~/.aws/credentials ~/.aws/credentials_bacup
fi

sc3_describe_instances=($(aws ec2 describe-instances --profile $1)) # > ./sc3_describe_instances.json
sc3_list_instance_profiles=($(aws iam list-instance-profiles --profile $1)) # > ./sc3_list_instance_profiles.json
sc3_list_roles=($(aws iam list-roles --profile $1)) # > ./sc3_list_roles.json
subnet_temp=($(aws ec2 describe-subnets --profile $1 | jq .Subnets[] | jq '.SubnetId'+'.Tags[2].Value' | grep "SecurityChallenge"))
subnet=$(echo ${subnet_temp/SecurityChallenge} | tr -d '"')
security_groups="sg-$(aws ec2 describe-security-groups --profile $1 | jq .SecurityGroups[] | jq '.GroupName'+'.GroupId' | grep "scenario3-ec2-ssh" | cut -d "-" -f5 | tr -d '"')"
mkdir ./sc3_folder_key
for ((i = 0; i < ${#user_email[@]}; i++))
    do
        echo "------------------------------------------------------------------------"
        echo ${username[i]}": "${user_email[i]}": "${access_key[i]}": "${secret_key[i]}": "${name[i]}
        echo "***"
        echo "Configure profile ${username[i]}"
        aws configure set aws_access_key_id ${access_key[i]} --profile user${i}
        aws configure set aws_secret_access_key ${secret_key[i]} --profile user${i}
        aws configure set region eu-central-1 --profile user${i}
        aws configure set output json --profile user${i}
        echo "***"
        echo "Remove role from instance profile"
        instance_profile_name=$(echo ${sc3_list_instance_profiles[@]} | jq .InstanceProfiles[].InstanceProfileName | tr -d '"' | grep ${name[i]})
        echo "instance_profile_name: "${instance_profile_name}
        # cgid=$(echo ${instance_profile_name} | cut -d "-" -f5 | cut -d "_" -f1)
        role_name_old="ec2-meek-role"
        # echo "cgid: "${cgid}
        echo "role_name_old: "${role_name_old}
        aws iam remove-role-from-instance-profile --instance-profile-name ${instance_profile_name} --role-name ${role_name_old} --profile user${i}
        echo "***"
        echo "Add role to instance profile"
        role_name=$(echo ${sc3_list_roles[@]} | jq .Roles[].RoleName | tr -d '"' | grep ${name[i]})
        echo "role_name: "${role_name}
        aws iam add-role-to-instance-profile --instance-profile-name ${instance_profile_name} --role-name ${role_name} --profile user${i}
        echo "***"
        echo "Create key pair"
        (aws ec2 create-key-pair --key-name sc3_${name[i]}_key --profile user${i} | jq .KeyMaterial | tr -d '"' ) >> ./sc3_folder_key/${name[i]}_key_pair.json
        echo "***"
        echo "Run instance"
        arn_instance_profile_name=$(echo ${sc3_list_instance_profiles[@]} | jq .InstanceProfiles[].Arn | tr -d '"' | grep ${name[i]})
        echo "arn_instance_profile_name: "${arn_instance_profile_name}
        aws ec2 run-instances --image-id ami-0718a1ae90971ce4d --iam-instance-profile Arn=${arn_instance_profile_name} --key-name sc3_${name[i]}_key --profile user${i} --instance-type t3.micro --tag-specifications "ResourceType=instance,Tags=[{Key=Owner,Value=${user_email[i]}}]" &
        echo "------------------------------------------------------------------------"
    done
    # echo "Are You made sure that VM's was created in AWS? (y/n)"
    # read y
    # if [${y}=="y"]
    #     then
    #     for ((i = 0; i < ${#user_email[@]}; i++))
    #     do

    #     done
    # fi
