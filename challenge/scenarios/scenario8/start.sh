#!/usr/bin/env bash

cd ./lambda

# Process 
for file in ./*
do
    # If file exists zip it to filename.zip
    [ -f $file ] && zip $( basename $file .py).zip $file
done