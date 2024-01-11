output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID Output"
}

output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "Public_Subnets_Cidr_Blocks Output"
}

output "public_subnets_cidr_blocks" {
  value       = module.vpc.public_subnets_cidr_blocks
  description = "Public_Subnets_Cidr_Blocks Output"
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "Private_Subnets_Cidr_Blocks Output"
}

output "private_subnets_cidr_blocks" {
  value       = module.vpc.private_subnets_cidr_blocks
  description = "Private_Subnets_Cidr_Blocks Output"
}

output "database_subnets" {
  value       = module.vpc.database_subnets
  description = "Database_Subnets Output"
}

output "database_subnet_group" {
  value       = module.vpc.database_subnet_group
  description = "Database_Subnet_Group Output"
}