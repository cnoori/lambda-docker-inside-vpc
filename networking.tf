module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-dev-1"
  cidr = "10.0.0.0/16"

  azs           = ["us-west-1c"]
  intra_subnets = ["10.0.3.0/24"]
  #private_subnets = ["10.0.1.0/24"]
  #public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false

  intra_subnet_tags = {
    name = "privet-subnet"
  }
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


resource "aws_vpc_endpoint" "s3-endpoint" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.us-west-1.s3"

  tags = {
    Name        = "s3-endpoint"
    Environment = "Dev"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3-endpoint-table-association" {
  route_table_id  = module.vpc.intra_route_table_ids[0]
  vpc_endpoint_id = aws_vpc_endpoint.s3-endpoint.id

}

resource "aws_security_group" "s3-lambda-sg" {
  name        = "s3-lambda-sg"
  description = "s3 endpoint secruity group"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "TCP"
    prefix_list_ids = [aws_vpc_endpoint.s3-endpoint.prefix_list_id]
  }

  tags = {
    Name        = "s3-lambda-sg"
    Environment = "Dev"
  }
}