output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "The ID of the VPC"
}

output "public_subnets_ids" {
  value       = aws_subnet.public_subnets[*].id
  description = "The IDs of the public subnets"
}

output "private_subnets_ids" {
  value       = aws_subnet.private_subnets[*].id
  description = "The IDs of the private subnets"
}