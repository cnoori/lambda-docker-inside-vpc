data "aws_caller_identity" "current" {}
data "aws_ecr_authorization_token" "token" {}

data "aws_ecr_image" "image" {
  repository_name = "lambda-ecr"
  image_tag       = "latest"
}

data "aws_ecr_repository" "repository" {
  name = "lambda-ecr"
}

data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}