# Terraform 초기구성
terraform {
  backend "s3" {
    bucket         = "myterraform-bucket-state-project-pkh"
    key            = "bastionhost/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "admin_user"
    dynamodb_table = "myTerraform-bucket-lock-project-pkh"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "admin_user"
}

module "BastionHost_SG" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "5.1.0"
  name            = "BastionHost_SG"
  description     = "BastionHost_SG"
  vpc_id          = local.vpc_id
  use_name_prefix = "false"

  ingress_with_cidr_blocks = [
    {
      from_port   = local.ssh_port
      to_port     = local.ssh_port
      protocol    = local.tcp_protocol
      description = "SSH"
      cidr_blocks = local.all_network
    },
    {
      from_port   = 0
      to_port     = 9000
      protocol    = local.tcp_protocol
      description = "All"
      cidr_blocks = local.all_network
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = local.any_port
      to_port     = local.any_port
      protocol    = local.any_protocol
      cidr_blocks = local.all_network
    }
  ]
}

# BastionHost EIP
resource "aws_eip" "BastionHost_eip" {
  instance = module.BastionHost.id
  tags = {
    Name = "BastionHost_EIP"
  }
}


#BastionHost
module "BastionHost" {
  source = "terraform-aws-modules/ec2-instance/aws"
  name   = local.ec2_name

  ami                    = local.ec2_ami
  instance_type          = local.ec2_type
  key_name               = local.ec2_keyname
  monitoring             = true
  vpc_security_group_ids = local.ec2_security_group_ids
  subnet_id              = local.subnet_id
  private_ip             = local.private_ip

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}