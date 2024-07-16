import json
import boto3

def invoke_function(event, context):
  statusCode, responseBody = handle(event)
  return {
    "isBase64Encoded": False,
    "statusCode": statusCode,
    "headers": {},
    "multiValueHeaders": {},
    "body": json.dumps({'message': responseBody})
  }

def handle(event):
  body = event.get('body')
  jbody = json.loads(event.get('body'))
  repodata = jbody.get("repository")
  reponame = repodata["name"]
  repourl = repodata["git_ssh_url"]
  print(reponame, repourl)
  
# build-docker-image-$user_id
#  projectname = "build-docker-image-" + reponame.replace("scenario8_", "")
  projectname = "deployment-pipeline-" + reponame.replace("scenario8_", "")
  
  cp = boto3.client('codepipeline')
  cp.start_pipeline_execution(name = projectname)
#  build = {
#    'projectName': projectname
#  }
  
#  cb.start_build(**build)
#  print('Launched a new CodeBuild project build ' + projectname)
  print('Launched a new CodePipline ' + projectname)

  if body is None:
    return 400, "missing body"

  return 200, body 
