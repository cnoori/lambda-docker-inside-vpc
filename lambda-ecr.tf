
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
    policy = file("s3_policy.json")
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


resource "aws_api_gateway_rest_api" "api-gw" {
  name        = "MyDemoAPI"
  description = "This is my API for demonstration purposes"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  # body = jsonencode({
  #   openapi = "3.0.1"
  #   info = {
  #     title   = "dev-stage"
  #     version = "1.0"
  #   }
  #   paths = {
  #     "/doc" = {
  #       get = {
  #         x-amazon-apigateway-integration = {
  #           httpMethod           = "GET"
  #           payloadFormatVersion = "1.0"
  #           type                 = "HTTP_PROXY"
  #           uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
  #         }
  #       }
  #       post = {
  #         x-amazon-apigateway-integration = {
  #           httpMethod           = "GET"
  #           payloadFormatVersion = "1.0"
  #           type                 = "HTTP_PROXY"
  #           uri                  = "https://ip-ranges.amazonaws.com/ip-ranges.json"
  #         }
  #       }
  #     }
  #   }
  # })
}



resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.docker_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api-gw.execution_arn}/*/*"
}


resource "aws_api_gateway_deployment" "dev-deplpoyment" {
  rest_api_id = aws_api_gateway_rest_api.api-gw.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api-gw.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "dev-stage" {
  deployment_id = aws_api_gateway_deployment.dev-deplpoyment.id
  rest_api_id   = aws_api_gateway_rest_api.api-gw.id
  stage_name    = "dev"
}

resource "aws_api_gateway_method_response" "response_200_get" {
  rest_api_id = aws_api_gateway_rest_api.api-gw.id
  resource_id = aws_api_gateway_resource.ApiResource.id
  http_method = "GET"
  status_code = "200"

  
}
resource "aws_api_gateway_method_response" "response_200_post" {
  rest_api_id = aws_api_gateway_rest_api.api-gw.id
  resource_id = aws_api_gateway_resource.ApiResource.id
  http_method = "POST"
  status_code = "200"
}

resource "aws_api_gateway_resource" "ApiResource" {
  rest_api_id = aws_api_gateway_rest_api.api-gw.id
  parent_id   = aws_api_gateway_rest_api.api-gw.root_resource_id
  path_part   = "doc"
}


resource "aws_api_gateway_method" "api-method-get" {
  rest_api_id   = aws_api_gateway_rest_api.api-gw.id
  resource_id   = aws_api_gateway_resource.ApiResource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "api-method-post" {
  rest_api_id   = aws_api_gateway_rest_api.api-gw.id
  resource_id   = aws_api_gateway_resource.ApiResource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get-integration" {
  rest_api_id             = aws_api_gateway_rest_api.api-gw.id
  resource_id             = aws_api_gateway_resource.ApiResource.id
  http_method             = aws_api_gateway_method.api-method-get.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.docker_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "post-integration" {
  rest_api_id             = aws_api_gateway_rest_api.api-gw.id
  resource_id             = aws_api_gateway_resource.ApiResource.id
  http_method             = aws_api_gateway_method.api-method-post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.docker_lambda.invoke_arn
}



