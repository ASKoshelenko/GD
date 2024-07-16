`aws configure --profile scenario1_user`

`aws iam list-attached-user-policies --user-name scenario1_user --profile Scenario1_user`

`aws iam list-policy-versions --policy-arn <generatedARN>/cg-scenario1_user-policy --profile Scenario1_user`

`aws iam get-policy-version --policy-arn <generatedARN>/cg-scenario1_user-policy --version-id <versionID> --profile Scenario1_user`

`aws iam set-default-policy-version --policy-arn <generatedARN>/cg-scenario1_user-policy --version-id <versionID> --profile Scenario1_user`