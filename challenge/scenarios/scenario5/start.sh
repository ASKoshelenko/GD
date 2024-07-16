#!/bin/bash
ssh-keygen -b 4096 -t rsa -f ./SecurityChallenge -q -N ""
ssh-keygen -b 4096 -t rsa -f ./admin5 -q -N ""

cd ./lambda
for file in ./*
do
    # If file exists zip it to filename.zip
    [ -f $file ] && zip $( basename $file .py).zip $file
done
cd ../assets/rce_app
zip -r app.zip $(ls)