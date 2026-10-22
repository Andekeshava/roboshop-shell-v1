#!/bin/bash

USER_ID=$(id -u)

log_folder="/var/log/roboshop"
log_file="${log_folder}/$0.log"
domain_name="jkrdigital.store"

if [ $USER_ID -ne 0 ]; then
   echo "Run the script using sudo access"
   exit 1
fi

timestamp(){
    data "+%D %T"
}

validate(){
    if [ $1 -ne 0 ]; then
       echo "${2} FAILED" | tee -a $log_file
       exit 1
    else
       echo "$(timestamp) [INFO] ====== ${2} SUCCESS" | tee -a $log_file
    fi     
}

mkdir -p $log_folder

echo "$(timestamp) [INFO] ====== SCRIPT STARTED EXECUTION ======"

dnf module disable nodejs -y            &>> $log_file
dnf module enable nodejs:24 -y          &>> $log_file
dnf install nodejs -y                   &>> $log_file
validate $? "Node.js Installation is"



