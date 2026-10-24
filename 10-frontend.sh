#!/bin/bash

USER_ID=$(id -u)

log_folder="/var/log/roboshop"
log_file="${log_folder}/$0.log"
domain_name="jkrdigital.store"
script_dir=$(dirname "$(realpath "$0")")

validate(){
if [ $1 -ne 0 ]; then
   echo "$(timestamp) [INFO] ====== ${2} FAILED" | tee -a $log_file
   exit 1
else
    echo "$(timestamp) [INFO] ====== ${2} SUCCESS" | tee -a $log_file
fi
}

timestamp(){
    date "+%D %T"
}

mkdir -p $log_folder

echo "$(timestamp) [INFO] ====== SCRIPT STARTED EXECUTION ======"

rm -rf /app
validate $? "Removing Old Code"

dnf module disable nginx -y &>> $log_file
dnf module enable nginx:1.26 -y &>> $log_file
dnf install nginx -y &>> $log_file
validate $? "Installation of Nginx"

systemctl enable nginx  &>> $log_file
systemctl start nginx   &>> $log_file
validate $? "Enabling and Starting Nginx"

rm -rf /usr/share/nginx/html/* &>> $log_file
curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/frontend-v4.zip &>> $log_file
validate $? "Downloading code into Nginx Default Location"

cd /usr/share/nginx/html &>> $log_file
unzip /tmp/frontend.zip &>> $log_file
validate $? "Unzipping the code"

sed -i "s/DOMAIN_NAME/$domain_name/g"  "$script_dir/roboshop.conf"
cp "$script_dir/roboshop.conf"  "/etc/nginx/default.d/roboshop.conf"

systemctl restart nginx
validate $? "Restarting Nginx"

echo "[INFO] ===== SCRIPT COMPLETED EXECUTION in $SECONDS seconds ====="
echo "$(timestamp) [INFO] ====== SCRIPT COMPLETED EXECUTION ======" | tee -a $log_file

