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

rm -rf /app
validate $? "Removing old code"

dnf module enable maven:3.9 -y  &>> $log_file
dnf install maven java-25-openjdk-devel -y  &>> $log_file
validate $? "Installation of maven and java"


dnf module enable maven:3.9 -y &>> "$log_file"
dnf install maven java-25-openjdk-devel -y &>> "$log_file"
validate $? "Installation of maven and Java 25"

export JAVA_HOME=/usr/lib/jvm/java-25-openjdk
export PATH="$JAVA_HOME/bin:$PATH"

java -version &>> "$log_file"
javac -version &>> "$log_file"
mvn -version &>> "$log_file"
validate $? "Checking Java and Maven versions"


id roboshop &>> $log_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate $? "Creating Roboshop user for shipping"
else
   echo "$(timestamp) [INFO] ====== Roboshop user for shipping is already created"
fi

mkdir /app
curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip  &>> $log_file
validate $? "Downloading Shipping service code"

cd /app
unzip /tmp/shipping.zip  &>> $log_file
validate $? "Unzipping the code into app directory"

mvn clean package &>> $log_file
validate $? "Installing maven dependencies"

mv target/shipping.jar shipping.jar  
validate $? "Moving target folder to shipping folder"

sed -i "s/DOMAIN_NAME/$domain_name/g"  "$script_dir/shipping.service"
cp "$script_dir/shipping.service"  "/etc/systemd/system/shipping.service"

dnf install mysql -y &>> $log_file
validate $? "Installing mysql ciient"

count=$(mysql -h "mysql.$domain_name" -u root -pRoboShop@1 -N -B -e "SELECT COUNT(*) FROM cities.cities;" 2>> "$log_file")

if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    mysql -h "mysql.$domain_name" -u root -pRoboShop@1 < /app/db/master-data.sql 2>> "$log_file"
    validate $? "Loading shipping data"
else
    echo "$(timestamp) [INFO] ====== Data is already loaded.....SKIPPING"
fi

mysql -h mysql.$domain_name -uroot -pRoboShop@1 < /app/db/app-user.sql $>>log_file
validate $? "Creating App User"

systemctl daemon-reload $log_file
systemctl enable shipping $log_file
systemctl start shipping $log_file
validate $? "Enabling and Starting Shipping"

systemctl restart shipping $log_file
validate $? "Restaring shipping"



echo "[INFO] ===== SCRIPT COMPLETED EXECUTION in $SECONDS seconds ====="
echo "$(timestamp) [INFO] ====== SCRIPT COMPLETED EXECUTION ======" | tee -a $log_file





