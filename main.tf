provider "aws" {
  region = var.aws_region
  #profile = var.profile 
}

# =============================================================================
# VPC MODULE
# =============================================================================

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

# =============================================================================
# KMS KEY FOR EKS ENCRYPTION
# =============================================================================

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.name}-eks-kms-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.name}-eks-key"
  target_key_id = aws_kms_key.eks.key_id
}

# =============================================================================
# EKS CLUSTER MODULE
# =============================================================================

module "eks" {
  source = "./modules/eks"
  
  name = var.name
  cluster_version = var.cluster_version
  
  vpc_id = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids = module.vpc.public_subnet_ids
  
  # Variável opcional para subnets específicas do Ingress
  ingress_subnets = var.ingress_subnets
  
  kms_key_arn = aws_kms_key.eks.arn
  
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  
  service_ipv4_cidr = var.service_ipv4_cidr
  
  node_groups = var.node_groups
  
  aws_auth_users = var.aws_auth_users
  aws_auth_roles = var.aws_auth_roles
  
  helm_releases = var.helm_releases
  
  tags = {
    Name        = var.name
    Environment = var.environment
    Terraform   = "true"
  }
}