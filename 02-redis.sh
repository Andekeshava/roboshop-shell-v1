#!/bin/bash

log_folder="/var/log/roboshop/"
log_file="${log_folder}/${0}.log"

mkdir -p $log_folder

USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
   echo "Run the script using SUDO access"
   exit 1
fi

timestamp(){
    date "+%D %T"
}

validate(){
    if [ ${1} -ne 0 ]; then
       echo "${2} is Failed" #| tee -a $log_file
       exit 1
    echo
       echo "${2} is Success" #| tee -a $log_file
    fi      
}

echo "$(timestamp) [INFO] ====== SCRIPT STARTED EXECUTION ======" | tee -a $log_file

dnf module disable redis -y &>> $log_file
dnf module enable redis:7 -y &>> $log_file
dnf install redis -y &>> $log_file
validate $? "Redis Installation"

sed -i -e 's/^bind 127.0.0.1/bind 0.0.0.0/' -e 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
validate $? "Allowing remote connection to redis"

systemctl enable redis &>> $log_file
systemctl start redis &>> $log_file
validate $? "Enabled and Started Redis"


echo "SCRIPT COMPLETED EXECUTION in $SECONDS seconds"
echo "$(timestamp) [INFO] ====== SCRIPT COMPLETED EXECUTION ======" | tee -a $log_file






