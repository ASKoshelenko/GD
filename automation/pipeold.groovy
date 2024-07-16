#!groovy
pipeline {
    agent any 
    stages {
        stage('Сlone') { 
             git url: '@github.com:RhinoSecurityLabs/cloudgoat.git ./CloudGoat'
                // 
            }
        }
        stage('install') { 
            steps {
                sh label: '', script: '''#!/bin/bash
                cd CloudGoat
                pip3 install -r ./core/python/requirements.txt
                chmod u+x cloudgoat.py
                     '''
              // 
            }
        }
        stage('Config user key') { 
            steps {
                sh label: '', script: '''#!/bin/bash
                cat <<EOF >> ~/.aws/credentials
                [User]
                aws_access_key_id = $key1 
                aws_secret_access_key = $key2

                     '''
                // 
            }
        } 
        stage('Config') { 
            steps {
                sh label: '', script: '''#!/bin/bash
                cat <<EOF >> ~/.aws/config
                [profile User]
                region = us-east-1
                output = json
                EOF
                ./cloudgoat.py config whitelist --auto
                ./cloudgoat.py create iam_privesc_by_rollback

                        '''
            
              //
            }
        }
    }
}
#!/bin/bash
git clone githttps://github.com/TkachukRoman/cloudgoat.git
cd CloudGoat
pip3 install -r ./core/python/requirements.txt
chmod u+x cloudgoat.py

cat <<EOF >> ~/.aws/credentials
[User]
aws_access_key_id = $key1 
aws_secret_access_key = $key2

cat <<EOF >> ~/.aws/config
[profile User]
region = us-east-1
output = json
EOF
cat <<EOF >> ~/vagrant/cloudgoat/config.yml
- default-profile: Irisha
EOF
./cloudgoat.py config whitelist --auto
./cloudgoat.py create iam_privesc_by_rollback
