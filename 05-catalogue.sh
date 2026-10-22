#!/bin/bash

USER_ID=$(id -u)

log_folder="/var/log/roboshop/"
log_file="${log_folder}/{0}.log"

if [ $1 -ne 0 ]; then
   echo "Run the script the using sudo access"
   exit 1
fi

timestamp(){
    date "+%D %T"
}

validate(){
    if [ $1 -ne 0 ]; then
       echo "${2} is FAILED" | tee -a $log_file
       exit 1
    else
       echo "$(timestamp) [INFO] ===== ${2} is SUCCESS" | tee -a $log_file
    fi   
}

dnf module disable nodejs -y
dnf module enable nodejs:24 -y
dnf install nodejs -y
validate $? "Node.js installation"

node -v
validate $? "Node.js version verification"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate $? "Roboshop user for catalogue creation"
else
   echo "$(timestamp) [INFO] ===== Roboshop user for catalogue is already created"
fi

mkdir -p /app
validate $? "Creating App Directory"

curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip
validate $? "Downloading the catalogue code"

cd /app
unzip /tmp/catalogue.zip
validate $? "Unzipping the catalogue code in App Directory"

npm install
validate $? "Installing dependencies"





      

