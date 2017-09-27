#!/bin/sh

bucket=$1
key=$2

awstopic="arn:aws:sns:us-east-1:806199016981:AmazonIpSpaceChanged"
name="aws-ip-address-summary"
region="us-east-1"

# Copy the sample file to the S3 bucket
aws s3 rm s3://$bucket/$key

# Get this AWS account number
account=$(aws sts get-caller-identity --output text --query 'Account')

topic="arn:aws:sns:$region:$account:$name"
echo "Deleting SNS topic $topic"
aws --region $region sns delete-topic --topic-arn $topic

policy="arn:aws:iam::$account:policy/$name"
echo "Deleting IAM policy $policy"
aws iam detach-role-policy --role-name $name --policy-arn $policy
#aws iam delete-policy-version --policy-arn $policy --version-id "v*"
aws iam delete-policy --policy-arn $policy 

role="arn:aws:iam::$account:role/$name"
echo "Deleting IAM role $role"
aws iam delete-role --role-name $name

function="arn:aws:lambda:$region:$account:function:$name"
echo "Deleting Lambda function $function"
aws --region $region lambda delete-function --function-name $name 

#function="arn:aws:lambda:$region:$account:function:$name"
#echo "Unsubscribing to SNS topic"
#aws --region $region sns unsubscribe --subscription-id $subscription

echo "DONE"
