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

timestamp(){
    date "+%D %T"
}

validate(){
    if [ $1 -ne 0 ]; then
       echo "$(timestamp) [INFO] ====== ${2} FAILED" | tee -a $log_file
       exit 1
    else
       echo "$(timestamp) [INFO] ====== ${2} SUCCESS" | tee -a $log_file
    fi   
}

echo "$(timestamp) [INFO] ====== SCRIPT STARTED EXECUTION ======"


mkdir -p ${log_folder}

dnf module enable maven:3.9 -y
dnf install maven java-25-openjdk-devel -y
validate $? "Installation of maven and java"



