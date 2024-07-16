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
    echo echo echo $(TitleCaseConverter "$username")
    code=$(echo $(< /dev/urandom tr -dc 0-9 | head -c${1:-9}))
    code=(${code:0:3}-${code:3:3}-${code:6})
    echo $code >> $CODES_PATH
done < <(tail -n +2 $USERS_PATH)

ssh-keygen -b 4096 -t rsa -f ./securitychallenge -q -N ""
ssh-keygen -b 4096 -t rsa -f ./admin4 -q -N ""
cd ./lambda
for file in ./*
do
    [ -f $file ] && zip $( basename $file .py).zip $file
done

