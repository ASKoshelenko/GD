#!/bin/bash

set -x

IFS=' ' read -a ARR <<< "$2"
PROFILE=$1
POLICY="arn:aws:iam::383607982478:policy/policy_scenario1_"
echo ${ARR[*]}
for i in ${ARR[@]}; do
    NAME=$i
    echo $NAME
    ARN="$POLICY$NAME"
    echo $ARN
    aws iam set-default-policy-version --policy-arn $ARN --version-id v1 --profile $PROFILE
done
