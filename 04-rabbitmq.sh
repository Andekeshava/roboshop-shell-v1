#!/bin/bash

log_folder="/var/log/roboshop"
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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "adding rabbitMQ repo"

dnf install erlang rabbitmq-server -y &>> $log_file
validate $? "RabbitMQ Installation"

systemctl enable rabbitmq-server &>> $log_file
systemctl start rabbitmq-server  &>> $log_file
validate $? "Enabled and Started RabbitMQ"

rabbitmqctl add_user roboshop roboshop123  &>> $log_file
validate $? "Adding roboshop User for rabbitMQ"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"   &>> $log_file
validate $? "Adding permissions for the roboshop user"

echo "[INFO] ===== SCRIPT COMPLETED EXECUTION in $SECONDS seconds ====="
echo "$(timestamp) [INFO] ===== SCRIPT COMPLETED EXECUTION ====="