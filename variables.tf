variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "name" {
  description = "Nome base dos recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
}

variable "availability_zones" {
  description = "Lista de AZs"
  type        = list(string)
}

variable "public_subnets" {
  description = "Lista de CIDRs das subnets públicas"
  type        = list(string)
}

variable "private_subnets" {
  description = "Lista de CIDRs das subnets privadas"
  type        = list(string)
}

variable "create_nat_gateway" {
  description = "Se deve criar NAT Gateway"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Ambiente (ex: dev, staging, prod)"
  type        = string
}
