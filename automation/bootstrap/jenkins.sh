#!/usr/bin/env bash

# variables
jenkins_url=localhost:8080
JENKINS_ADMIN_USER=CloudGoat
JENKINS_ADMIN_PASSWORD=admin
JENKINS_CONF_PATH=/etc/default/jenkins
JENKINS_HOME=/
path1="/usr/local/src/"

# install packet manager and update
apt update

# java ans jenkins installation
apt install default-jdk -y
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
add-apt-repository universe
apt update
apt install jenkins -y

# Create new admin user for jenkins and install some plugins
sleep 60
wget -q "http://localhost:8080/jnlpJars/jenkins-cli.jar" -P /opt
key=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "jenkins.model.Jenkins.instance.securityRealm.createAccount(\"${JENKINS_ADMIN_USER}\", \"${JENKINS_ADMIN_PASSWORD}\")" | java -jar /opt/jenkins-cli.jar -auth admin:${key} -s "http://${jenkins_url}" groovy =
java -jar /opt/jenkins-cli.jar -s "http://${jenkins_url}" -auth ${JENKINS_ADMIN_USER}:${JENKINS_ADMIN_PASSWORD} install-plugin dashboard-view \
cloudbees-folder antisamy-markup-formatter build-name-setter build-timeout config-file-provider credentials-binding embeddable-build-status rebuild ssh-agent \
throttle-concurrents timestamper ws-cleanup workflow-aggregator github-organization-folder pipeline-stage-view build-pipeline-plugin conditional-buildstep \
parameterized-trigger copyartifact git gitlab-plugin github ssh-slaves role-strategy email-ext ssh emailext-template greenballs blueocean aws-credentials aws-java-sdk jackson2-api

# Disable jenkins setup wizard
sed -i -e '/^\(JAVA_ARGS=\).*/{s//\1"-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"/;:a;n;ba;q}' \
-e '$iJAVA_ARGS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"' /etc/default/jenkins

mkdir -p /var/lib/jenkins/init.groovy.d
mv -f /tmp/basic-security.groovy /var/lib/jenkins/init.groovy.d/basic-security.groovy

# apply changes and clear trash
systemctl restart jenkins
sleep 15
rm -f /var/lib/jenkins/init.groovy.d/basic-security.groovy