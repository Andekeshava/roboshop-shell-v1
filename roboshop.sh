#!/bin/bash

instance_type="t3.micro"
ami_id="ami-0055977a6e828a4f4"
domain_name="jkrdigital.store"
hosted_zone_id="Z021725625Q0QW58HS52C"

for instance in "$@"
do
   echo "Creating Instance: $instance"
   instance_id=$(aws ec2 run-instances \
    --image-id $ami_id \
    --instance-type $instance_type \
    --security-groups "roboshop-common" "roboshop-$instance" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]')

    echo "$instance ID: $instance_id"

    if [ $instance != "frontend" ]; then
       IP=$(aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[*].Instances[*].PrivateIpAddress' \
            --output text)    

        r53_record="${instance}.${domain_name}"
    else
       IP=$(aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[*].Instances[*].PublicIpAddress' \
            --output text)

        r53_record="${domain_name}"    
    fi

    #update route53 records
    aws route53 change-resource-record-sets \
    --hosted-zone-id ${hosted_zone_id} \
    --change-batch '{
        "Changes": [
          {
              "Action": "UPSERT",
               "ResourceRecordSet": {
               "Name": "'${r53_record}'",
               "Type": "A",
               "TTL": 1,
               "ResourceRecords": [{"Value": "'${IP}'"}]
                }
            }
        ]
    }'    

done