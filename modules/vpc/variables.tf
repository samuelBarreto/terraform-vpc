variable "name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "create_nat_gateway" {
  type    = bool
  default = true
}

variable "environment" {
  description = "Ambiente (ex: dev, staging, prod)"
  type        = string
}