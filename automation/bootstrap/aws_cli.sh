#!/usr/bin/env bash

# Install python and awscli
apt update
apt install python3.7 -y
apt install python3-pip -y
pip3 install boto3
pip3 install --upgrade requests
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
 ./aws/install