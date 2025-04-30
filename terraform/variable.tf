variable "aws_region" {
  type        = string
  description = "The AWS region to deploy resources in"
  default     = "ap-southeast-2"
}

variable "count_public_subnets" {
  type        = number
  description = "The number of public subnets"
  default     = 3
}

variable "count_private_subnets" {
  type        = number
  description = "The number of private subnets"
  default     = 3

}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
  default     = "nextjs-vpc"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "The list of public subnets"
  default     = ["10.0.1.0/24"]
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "The list of private subnets"
  default     = ["10.0.2.0/24"]
}

