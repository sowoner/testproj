output "bastion_id" {
  value = module.BastionHost.id
}

output "bastion_EIP" {
  value = aws_eip.BastionHost_eip.public_ip
}

output "bastion_private_ip" {
  value = module.BastionHost.private_ip
}