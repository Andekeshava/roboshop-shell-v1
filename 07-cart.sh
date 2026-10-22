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

dnf module disable nodejs -y  &>> $log_file
dnf module enable nodejs:24 -y  &>> $log_file
dnf install nodejs -y  &>> $log_file
validate $? "Node.js Installation"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate $? "Adding roboshop user"
else
   echo "Roboshop user already created"
fi

rm -rf /app &>> $log_file
validate $? "$(timestamp) [INFO] ====== Removing Old Code"

mkdir /app
curl -L -o /tmp/cart.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/cart-v4.zip  &>> $log_file
validate $? "Downloading the cart application code"

cd /app
unzip /tmp/cart.zip  &>> $log_file
validate $? "Unzipping the code into app directory"

npm install  &>> $log_file
validate $? "Installing dependencies into app directory"

sed -i "s/DOMAIN_NAME/$domain_name/g"    "$script_dir/cart.service"
cp "$script_dir/cart.service"   "/etc/systemd/system/cart.service"

systemctl daemon-reload  &>> $log_file
systemctl enable cart  &>> $log_file
systemctl start cart  &>> $log_file
validate $? "Enabled and Starting Cart service"

systemctl restart user
validate $? "Restarting user"

echo "[INFO] ===== SCRIPT COMPLETED EXECUTION in $SECONDS seconds ====="
echo "$(timestamp) [INFO] ====== SCRIPT COMPLETED EXECUTION ======" | tee -a $log_file

