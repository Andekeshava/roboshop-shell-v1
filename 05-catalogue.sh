#!/bin/bash

USER_ID=$(id -u)

log_folder="/var/log/roboshop/"
log_file="${log_folder}/{0}.log"
domain_name="jkrdigital.store"
script_dir=$(dirname "$(realpath "$0")")

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

dnf module disable nodejs -y &>> $log_file
dnf module enable nodejs:24 -y &>> $log_file
dnf install nodejs -y &>> $log_file
validate $? "Node.js installation"

node -v &>> $log_file
validate $? "Node.js version verification"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $log_file
   validate $? "Roboshop user for catalogue creation"
else
   echo "$(timestamp) [INFO] ===== Roboshop user for catalogue is already created"
fi

rm -rf /app
validate $? "Removing old code"

mkdir -p /app
validate $? "Creating App Directory"

curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip &>> $log_file
validate $? "Downloading the catalogue code"

cd /app
unzip /tmp/catalogue.zip &>> $log_file
validate $? "Unzipping the catalogue code in App Directory"

npm install &>> $log_file
validate $? "Installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g"  "$script_dir/catalogue.service"   &>> $log_file
cp "$script_dir/catalogue.service"  /etc/systemd/system/catalogue.service 

systemctl daemon-reload  &>> $log_file
systemctl enable catalogue  &>> $log_file
systemctl start catalogue  &>> $log_file
validate $? "Enabled and Starting Catalogue Service"

cp "$script_dir/mongo.repo"  /etc/yum.repos.d/mongo.repo
validate $? "Adding Mongo Repo"

dnf install mongodb-mongosh -y  &>> $log_file
validate $? "Installing MongoDB Client"


product_count=$(mongosh --host mongodb.$domain_name --quiet --eval 'db.getSiblingDB("catalogue").products.countDocuments()' 2> $log_file)
validate $? "Mongodb connecting"


if [ "$product_count" -eq 0 ]; then
   mongosh --host mongodb.$domain_name </app/db/master-data.js  &>> $log_file
   validate $? "Products loading"
else
   echo "$(timestamp) [INFO] ===== Products are already Loaded...Proceeding with next step"
fi

systemctl restart catalogue  &>> $log_file

echo "[INFO] ===== SCRIPT COMPLETED EXECUTION in $SECONDS seconds ====="
echo "$(timestamp) [INFO] ===== SCRIPT COMPLETED EXECUTION ====="



      

