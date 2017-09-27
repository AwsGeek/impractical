#### Background
AWS maintains a list of IP addresses that are used by it's services. When this list is updated, AWS sends a notification to a well know SNS topic. Subscribers to this topic can use the notification as a trigger to take some action, such as refresh a firewall whitelist or update a security group rule. 

#### Goal
Send a notification to another SNS topic containing a summary of the most recent changes to the AWS IP address list.
