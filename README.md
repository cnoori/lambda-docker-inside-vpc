# lambda-docker-inside-vpc
A basic Lambda function configured with a VPC without internet access, to lists buckets in s3 with s3 endpoint.  It uses the ECR for Docker image

Pre Req:
1- install and configure aws cli with you key and secret to login > "aws configure"

1- Run docker build on the dockerfile and upload to AWS ECR
2- Update lambda-ecr line #8 with your new ECR repository name
3- done, run terraform init > plan > apply 