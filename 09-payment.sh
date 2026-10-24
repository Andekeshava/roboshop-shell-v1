#!/bin/bash

USER_ID=$(id -u)

log_folder="var/log/roboshop"
log_file="${log_folder}/${0}.log"
domain_name="jkrdigital.store"
script_dir=$(dirname "$(realpath "${0}")")

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
validate $? "Removing Old code"

dnf install python3.14 python3.14-pip -y &>> $log_file
python3.14 --version &>> $log_file
validate $? "Installation of Python"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   validate $? "Creating Roboshop User"
else
   echo "$(timestamp) [INFO] ====== Roboshop User already Exists......SKIPPING"
fi

mkdir /app
curl -L -o /tmp/payment.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/payment-v4.zip &>> $log_file
validate $? "Downloading the code for payment"

cd /app
unzip /tmp/payment.zip &>> $log_file
validate $? "Unzipping the payment code into app directory"

cd /app
python3.14 -m venv /app/.venv &>> $log_file
/app/.venv/bin/pip install -r requirements.txt &>> $log_file
validate $? "Installing the dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g"  "$script_dir/payment.service"
cp "$script_dir/payment.service"  "/etc/systemd/system/payment.service"

systemctl daemon-reload &>> $log_file
systemctl enable payment &>> $log_file
systemctl start payment &>> $log_file
validate $? "Enabling and Starting payment"

systemctl restart shipping &>> $log_file
validate $? "Restarting shipping"

echo "[INFO] ===== SCRIPT COMPLETED EXECUTION in $SECONDS seconds ====="
echo "$(timestamp) [INFO] ====== SCRIPT COMPLETED EXECUTION ======" | tee -a $log_file
