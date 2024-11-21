import boto3
import os

sns = boto3.client('sns')
sns_topic_arn = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        message = f"New file uploaded: {key} in bucket {bucket}"
        
        sns.publish(
            TopicArn=sns_topic_arn,
            Message=message,
            Subject="S3 File Upload Notification"
        )
    return {"statusCode": 200}
