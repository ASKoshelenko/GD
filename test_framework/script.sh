#!/bin/bash
#rm ./db.json
#aws dynamodb scan --table-name users --profile $1 > ./db.json
data_base=$(aws dynamodb scan --table-name users --profile $1)
if [[ ($2 = "scenario1") || ($2 = "scenario2") || ($2 = "scenario3") ]]
  then
    user_email=($(echo ${data_base} | jq .Items[].email.S | tr -d '"'))
    name=($(echo ${data_base} | jq .Items[].email.S | tr -d '"' | cut -d @ -f 1))
    secret_key=($(echo ${data_base} | jq .Items[].scenarios.M.$2.M.secret_key.S | tr -d '"'))
    access_key=($(echo ${data_base} | jq .Items[].scenarios.M.$2.M.access_key.S | tr -d '"'))
    username=($(echo ${data_base} | jq .Items[].scenarios.M.$2.M.username.S | tr -d '"'))
    echo "Username:          User_email:      Access_key:           Secret_key"
    valid_cred=0
    for ((i = 0; i < ${#user_email[@]}; i++))
        do
            echo "№ "${i}":  "${username[i]}": "${user_email[i]}": "${access_key[i]}": "${secret_key[i]}
            #sleep 5s
            if [ ${username[i]} != 'null' ]
              then
              valid_cred=$[valid_cred + 1]
            fi
    done
    echo "valid credentials: " ${valid_cred}
fi
if [ $2 = "scenario6" ]
  then
    user_email=($(echo ${data_base} | jq .Items[].email.S | tr -d '"'))
    name=($(echo ${data_base} | jq .Items[].email.S | tr -d '"' | cut -d @ -f 1))
    secret_key=($(echo ${data_base} | jq .Items[].scenarios.M.$2.M.secret_key_user1.S | tr -d '"'))
    access_key=($(echo ${data_base} | jq .Items[].scenarios.M.$2.M.access_key_user1.S | tr -d '"'))
    username1=($(echo ${data_base} | jq .Items[].scenarios.M.$2.M.username_user1.S | tr -d '"'))
    username2=($(echo ${data_base} | jq .Items[].scenarios.M.$2.M.username_user2.S | tr -d '"'))
    echo "Username:          User_email:      Access_key:           Secret_key"
    valid_cred=0
    for ((i = 0; i < ${#user_email[@]}; i++))
        do
            echo "№ "${i}":  "${username1[i]}": "${user_email[i]}": "${access_key[i]}": "${secret_key[i]}
            #sleep 5s
            if [ ${username1[i]} != 'null' ]
              then
              valid_cred=$[valid_cred + 1]
            fi
    done
    echo "valid credentials: " ${valid_cred}
fi