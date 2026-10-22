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

alternatives --set java /usr/lib/jvm/java-25-openjdk/bin/java
validate $? "Setting java 15 as default version"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "Setting Java Home for maven"

java -version
mvn -v
validate $? "Checking the Javan and Maven version"

id roboshop
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate $? "Creating Roboshop user for shipping"
else
   echo "Roboshop user for shipping is already created"
fi

mkdir /app
curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip  &>> $log_file
validate $? "Downloading Shipping service code"

cd /app
unzip /tmp/shipping.zip
validate $? "Unzipping the code into app directory"

mvn clean package &>> $log_file
validate $? "Installing maven dependencies"

mv target/shipping.jar shipping.jar
validate $? "Moving target folder to shipping folder"

sed -i "s/DOMAIN_NAME/$domain_name/g"  "$script_dir/shipping.service"
cp "$script_dir/shipping.service"  "/etc/systemd/system/shipping.service"

dnf install mysql -y &>> $log_file
validate $? "Installing mysql ciient"







