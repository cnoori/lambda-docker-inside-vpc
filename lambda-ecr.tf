
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


resource "aws_iam_role" "terraform_function_role" {
  name               = "terraform_function_role"
  assume_role_policy = data.aws_iam_policy_document.AWSLambdaTrustPolicy.json

  inline_policy {
    name   = "S3-Lambda-Access"
    policy = "${file("s3_policy.json")}"
  }
}


resource "aws_iam_role_policy_attachment" "terraform_lambda_policy" {
  role       = aws_iam_role.terraform_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


resource "aws_lambda_function" "docker_lambda" {
  image_uri     = "${data.aws_ecr_repository.repository.repository_url}@${data.aws_ecr_image.image.image_digest}"
  function_name = "lambda-ecr"
  role          = aws_iam_role.terraform_function_role.arn
  package_type  = "Image"

  vpc_config {
    subnet_ids         = module.vpc.intra_subnets
    security_group_ids = [aws_security_group.s3-lambda-sg.id]
  }

}

