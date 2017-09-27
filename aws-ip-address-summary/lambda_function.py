import os
import json
import boto3
import urllib

def count_ipv4_addresses(ranges):
    count = 0
    for range in ranges:
        count += (1<<(32-int(range.split("/")[-1])))        
    return count

def get_ipv4_ranges(data):
    ranges = [] 
    response = json.loads(data)
    for k in response['prefixes']:
        if k['service'] == 'AMAZON':
            ranges.append(k['ip_prefix'])
    return ranges

def get_ipv4_info(data):
    ranges = get_ipv4_ranges(data)
    range_count = len(ranges)
    address_count = count_ipv4_addresses(ranges)
    return {'ranges': ranges, 'range_count': range_count, 'address_count': address_count}
    
def lambda_handler(event, context):
    
    url = json.loads(event['Records'][0]['Sns']['Message'])['url']
    
    # Download and read current IP list
    current_data = urllib.request.urlopen(url).read()
    current_info  = get_ipv4_info(current_data)
    
    s3 = boto3.resource('s3') 
    # The previous IP list must already exist in the bucket
    previous_data = s3.Object(os.environ['s3_bucket'], os.environ['s3_key']).get()['Body'].read()
    previous_info  = get_ipv4_info(previous_data)

    # Save the current IP list for the next iteration
    s3.Bucket(os.environ['s3_bucket']).put_object(Key=os.environ['s3_key'], Body=current_data)

    message = "AWS IPv4 Address Summary: "
    message += "IP Ranges: %s, " % current_info['range_count']
    message += "IP Addresses: %s, " % current_info['address_count']
    message += "IP Addresses Added: %s" % (current_info['address_count'] - previous_info['address_count'])
    
    sns = boto3.client('sns')
    sns.publish(
        TargetArn=os.environ['sns_topic'],
        Message=message
    )
        
    return message
