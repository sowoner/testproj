locals {
  vpc_id                 = data.terraform_remote_state.vpc_remote_data.outputs.vpc_id
  ssh_port               = 22
  tcp_protocol           = "tcp"
  all_network            = "0.0.0.0/0"
  any_port               = "0"
  any_protocol           = "-1"
  ec2_name               = "BastionHost"
  ec2_ami                = "ami-086cae3329a3f7d75" //ubuntu(22.04LTS)
  ec2_type               = "t2.micro"
  ec2_keyname            = data.aws_key_pair.EC2-Key.key_name
  subnet_id              = data.terraform_remote_state.vpc_remote_data.outputs.public_subnets[1]
  ec2_security_group_ids = [data.terraform_remote_state.eks_remote_data.outputs.eks_cluster_sg, module.BastionHost_SG.security_group_id]
  private_ip             = "192.168.2.77"
}