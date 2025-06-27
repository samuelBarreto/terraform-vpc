provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source              = "./modules/vpc"
  name                = var.name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets
  create_nat_gateway  = var.create_nat_gateway
  environment         = var.environment
}