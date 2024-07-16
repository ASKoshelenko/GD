#!/usr/bin/env bash

# Prepare secret
SECRET_PATH="./assets/cardholders_corporate.csv"
USERS_PATH="../users.csv"
CODES_PATH="./codes.txt"

TitleCaseConverter() {
    sed 's/.*/\L&/; s/[a-z]*/\u&/g' <<<"$1"    
}

while IFS="," read -r username email category
do
    echo $(TitleCaseConverter "$username")
    code=$(echo $(< /dev/urandom tr -dc 0-9 | head -c${1:-9}))
    code=(${code:0:3}-${code:3:2}-${code:5})
    echo $code >> $CODES_PATH
    lines=$(wc -l < $SECRET_PATH)
    rand=$((RANDOM % lines))
    sed -i -e "${rand}s/.*/$((rand - 1)),$code,Secret,ToPass,Is,SSN,$(TitleCaseConverter "$username"),Gender,127.0.0.1/" $SECRET_PATH
done < <(tail -n +2 $USERS_PATH)


# generate ssh keys pair
ssh-keygen -b 4096 -t rsa -f ./challenge -q -N ""

# Prepare lambda functions for deploy 
cd ./lambda
for file in ./*
do
    # If file exists zip it to filename.zip
    [ -f $file ] && zip $( basename $file .py).zip $file
done
