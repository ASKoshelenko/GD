#!groovy
pipeline {
    agent any 
    stages {
        stage ('test'){
            steps {
                sh label: '', script: '''
                    #!/bin/bash
                    if cloudgoat.py list deployed | grep -q "$scenario";then
                    echo "Scenario already exists." 
                    else 
                    cloudgoat.py create $scenario
                    fi  '''
                     // 
            }
    }    }
}  