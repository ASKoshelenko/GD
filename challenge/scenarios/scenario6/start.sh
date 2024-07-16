#!/usr/bin/env bash

# Prepare secret
codes=()
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
    code=(${code:0:2}-${code:2:3}-${code:4})
    echo $code >> $CODES_PATH
done < <(tail -n +2 $USERS_PATH)

ssh-keygen -b 4096 -t rsa -f ./SecurityChallenge -q -N ""
ssh-keygen -b 4096 -t rsa -f ./admin6 -q -N ""
cd ./lambda
for file in ./*
do
    # If file exists zip it to filename.zip
    [ -f $file ] && zip $( basename $file .py).zip $file
done