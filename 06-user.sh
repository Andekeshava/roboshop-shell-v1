#!/bin/bash

USER_ID=$(id -u)

log_folder="/var/log/roboshop"
log_file="${log_folder}/$0.log"
domain_name="jkrdigital.store"
script_dir=$(dirname "$(realpath "$0")")

if [ $USER_ID -ne 0 ]; then
   echo "Run the script using sudo access"
   exit 1
fi

timestamp(){
    date "+%D %T"
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

rm -rf /app
validate $? "Removing old code"


dnf module disable nodejs -y            &>> $log_file
dnf module enable nodejs:24 -y          &>> $log_file
dnf install nodejs -y                   &>> $log_file
validate $? "Node.js Installation is"

id roboshop
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate $? "Adding roboshop user"
else
    echo "Roboshop user is already created....==== SKIPPING ===="
fi

mkdir /app
curl -L -o /tmp/user.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/user-v4.zip  &>> $log_file
validate $? "Downloading the application code"

unzip /tmp/user.zip &>> $log_file
validate $? "Unzipping the code into App directory"

npm install &>> $log_file
validate $? "Installing the dependencies is"

sed -i "s/DOMAIN_NAME/$domain_name/g"    "$script_dir/user.service"  &>> $log_file
cp "$script_dir/user.service"   "/etc/systemd/system/user.service"

systemctl daemon-reload
systemctl enable user
systemctl start user
validate $? "Enabling and Starting user is"

systemctl restart user
validate $? "Restarting user"

echo "[INFO] ===== SCRIPT COMPLETED EXECUTION in $SECONDS seconds ====="
echo "$(timestamp) [INFO] ====== SCRIPT COMPLETED EXECUTION ======" | tee -a $log_file








      

