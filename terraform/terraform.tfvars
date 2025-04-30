aws_region            = "ap-southeast-2"
count_private_subnets = 3
count_public_subnets  = 3
vpc_name              = "nextjs-vpc"
vpc_cidr_block        = "10.0.0.0/16"
public_subnets_cidr   = ["10.0.1.0/24"]
private_subnets_cidr  = ["10.0.2.0/24"]