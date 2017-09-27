#!/bin/sh

bucket=$1
key=$2
email=$3

awstopic="arn:aws:sns:us-east-1:806199016981:AmazonIpSpaceChanged"
name="aws-ip-address-summary"
region="us-east-1"

# Copy the sample file to the S3 bucket
aws s3 cp ip-ranges.json s3://$bucket/$key

# Get this AWS account number
account=$(aws sts get-caller-identity --output text --query 'Account')


############################
# SNS Topic & Subscription #
############################
echo "Creating SNS topic"
aws --region $region sns create-topic \
   --name $name
topic="arn:aws:sns:$region:$account:$name"

echo "Creating SNS subscription to $topic"
aws --region $region sns subscribe \
  --topic-arn $topic \
  --protocol email \
  --notification-endpoint $email


# Update the access policy json with particulars
echo "Updating IAM policyi file"
sed -i "s/<SNS Topic ARN>/$topic/g" access-policy.json
sed -i "s/<S3 Bucket ARN>/arn:aws:s3:::$bucket/g" access-policy.json


#####################
# IAM Policy & Role #
#####################
echo "Creating IAM policy"
aws iam create-policy \
  --policy-name $name \
  --policy-document file://access-policy.json
policy="arn:aws:iam::$account:policy/$name"

echo "Creating IAM role"
aws iam create-role \
  --role-name $name \
  --assume-role-policy-document file://trust-policy.json
role="arn:aws:iam::$account:role/$name"

echo "Attaching IAM role & policy"
aws iam attach-role-policy \
  --role-name $name \
  --policy-arn $policy

sleep 10 # Until the Role is ready for the Lambda function

#############################
# Lambda Function & Trigger #
#############################
zip $name.zip lambda_function.py
echo "Creating Lambda function"
aws --region $region lambda create-function \
  --function-name aws-ip-address-summary \
  --runtime python3.6 \
  --role $role \
  --handler lambda_function.lambda_handler \
  --timeout 60 \
  --environment "Variables={sns_topic=$topic,s3_bucket=$bucket,s3_key=$key}" \
  --zip-file fileb://$name.zip
function="arn:aws:lambda:$region:$account:function:$name"

echo "Creating Lambda trigger"
aws --region $region lambda add-permission \
  --function-name $name \
  --statement-id $name \
  --action lambda:InvokeFunction \
  --principal sns.amazonaws.com \
  --source-arn $awstopic

echo "Subscribing to SNS topic"
aws --region $region sns subscribe \
  --topic-arn $awstopic \
  --protocol lambda \
  --notification-endpoint $function

echo "DONE"
