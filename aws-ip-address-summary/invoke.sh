#!/bin/sh

name="aws-ip-address-summary"
region="us-east-1"

aws --region $region lambda invoke \
  --function-name $name \
  --invocation-type Event \
  --payload file://payload.json \
  outputfile.txt

echo "DONE"
