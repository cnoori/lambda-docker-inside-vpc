provider "aws" {
  region = "us-east-1"
}

provider "docker" {
  registry_auth {
    address  = local.aws_ecr_url
    username = data.aws_ecr_authorization_token.token.username
    password = data.aws_ecr_authorization_token.token.password
  }
}



locals {
  aws_ecr_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazon.com"
}