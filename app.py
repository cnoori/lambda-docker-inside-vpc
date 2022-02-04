import boto3

def handler(event, context):
    s3 = boto3.resource('s3')
    for bucket in s3.buckets.all():
        print(bucket.name)