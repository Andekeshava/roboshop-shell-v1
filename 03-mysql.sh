#!/bin/bash

log_folder="/var/log/roboshop/"
log_file="${log_folder}/${0}.log"

USER_ID=$(id -u)

if [ $USER_ID -ne 0 ]; then
   echo "Run the script usig sudo access"
   exit 1
fi

mkdir -p $log_folder

timestamp(){
    date "+%D %T"
}

echo "$(timestamp) [INFO] ===== SCRIPT STARTED EXECUTION ====="

validate(){
    if [ $1 -ne 0 ]; then
       echo "${2} is FAILED" | tee -a $log_file
       exit 1
    else
       echo "${2} is SUCCESS" | tee -a $log_file
    fi   
}

dnf module enable mysql:8.4 -y &>> $log_file
dnf install mysql-server -y &>> $log_file
validate $? " MySql Installation is"

systemctl enable mysqld &>> $log_file
systemctl start mysqld &>> $log_file
validate $? "Enabled and Started MySql"

mysql_secure_installation --set-root-pass RoboShop@1 &>> $log_file
validate $? "MySQL root password steup is"

echo "[INFO] ===== SCRIPT COMPLETED EXECUTION in $SECONDS seconds ====="
echo "$(timestamp) [INFO] ===== SCRIPT COMPLETED EXECUTION ====="










