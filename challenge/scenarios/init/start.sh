#!/bin/bash

cd ./lambda

# Process 
for name in ./*
do
    # If file exists zip it to filename.zip
    [ -f $name ] && zip $( basename $name .py).zip $name
done
cd ../assets/
zip -r SendingNotifications.zip $(ls)
cd ../resultlambda/
zip -r ResultLambda.zip $(ls)