#!/bin/bash

USER_ID=$(id -u)
log_folder="/var/log/roboshop"
log_file="${log_folder}/$0.log"
domain_name="jkrdigital.store"
script_dir=$(dirname "$(realpath "$0")")

if [ $USER_ID -ne 0 ]; then
   echo "run the script using sudo access"
   exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
       echo "${2} FAILED"
       exit 1
    else
       echo "${2} SUCCESS"
}

mkdir -p ${log_folder}

dnf module disable nodejs -y
dnf module enable nodejs:24 -y
dnf install nodejs -y
validate $? "Node.js Installation"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate $? "Adding roboshop user"
else
   echo "Roboshop user already created"
fi

rm -rf /app
validate $? "Removing Old Code"

mkdir /app
curl -L -o /tmp/cart.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/cart-v4.zip
validate $? "Downloading the cart application code"

cd /app
unzip /tmp/cart.zip
validate $? "Unzipping the code into app directory"

