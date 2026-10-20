#!/bin/bash

USER_ID=$(id -u)

log_folder="/var/log/roboshop"
log_file="${log_folder}/{0}.log"

if [ $USER_ID -ne 0 ]; then
    echo "Please run the script using SUDO access"
    exit 1
fi

mkdir -p ${log_file}

echo "$(date "+%D %T") [INFO] ====== SCRIPT STARTED ====="

validate(){
   if [ $1 -ne 0 ]; then
       echo "${2} is Failed"
       exit 1
   else
       echo "${2} is Success"
   fi
}

cp mongodb.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding mongo repo"

dnf install mongodb-org -y &>> ${log_file}
validate $? "Mongodb Installation"

systemctl enable mongod &>> ${log_file}
systemctl start mongod &>> ${log_file}
validate $? "Enabled and Started MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
systemctl restart mongod &>> ${log_file}
validate $? "Restarted MongoDB"

echo "script completed execution in $SECONDS seconds"
echo "$(date "+%D %T") [INFO] ====== SCRIPT COMPLETED ====="
