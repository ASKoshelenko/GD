#!/usr/bin/env bash

# install unzip
apt update
apt install unzip zip -y

# download terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update && apt install terraform

# export terraform to path
echo "export PATH=\$PATH:/opt/terraform" > /etc/profile.d/terraform_path.sh
chmod +x /etc/profile.d/terraform_path.sh
source /etc/profile.d/terraform_path.sh
