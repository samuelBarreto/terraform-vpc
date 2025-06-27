aws_region         = "us-east-1"
environment        = "dev"
name               = "eks-vpc"
vpc_cidr           = "192.168.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnets     = ["192.168.0.0/18", "192.168.64.0/18"]
private_subnets    = ["192.168.128.0/18", "192.168.192.0/18"]
create_nat_gateway = true

