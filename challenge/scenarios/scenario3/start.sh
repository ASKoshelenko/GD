#!/usr/bin/env bash
# generate key pair for ec2 instance
ssh-keygen -b 4096 -t rsa -f ./cloudgoat -q -N ""

# Prepare lambda functions for deploy 
cd ./lambda
for file in ./*
do
    # If file exists zip it to filename.zip
    [ -f $file ] && zip $( basename $file .py).zip $file
done