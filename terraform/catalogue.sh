#!/bin/bash

APP_VERSION=$1
echo "app_version: $APP_VERSION"
yum install python3-devel python3-pip -y
pip3 install ansible botocore boto3
cd /tmp
ansible-pull -U https://github.com/Rashid-Khan-Github/ansible_roboshop_roles_dev.git -e app_version=${APP_VERSION} -e component=catalogue main.yaml