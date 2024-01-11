# Terraform 초기구성
terraform {
  backend "s3" {
    bucket         = "myterraform-bucket-state-project-pkh"
    key            = "vpc/terraform.tfstate"
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

#project-VPC
module "vpc" {
  source           = "terraform-aws-modules/vpc/aws"
  version          = "5.1.1"
  name             = local.name
  azs              = local.azs
  cidr             = local.cidr
  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  tags = {
    "TerraformManaged" = "true"
  }
}

# Security-Group (NAT-Instance)
module "NAT_SG" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "5.1.0"
  name            = "NAT_SG"
  description     = "All Traffic"
  vpc_id          = module.vpc.vpc_id
  use_name_prefix = "false"

  ingress_with_cidr_blocks = [
    {
      from_port   = local.any_port
      to_port     = local.any_port
      protocol    = local.any_protocol
      cidr_blocks = local.private_subnets[0]
    },
    {
      from_port   = local.any_port
      to_port     = local.any_port
      protocol    = local.any_protocol
      cidr_blocks = local.private_subnets[1]
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

# NAT Instance ENI(Elastic Network Interface)
resource "aws_network_interface" "NAT_ENI" {
  subnet_id         = module.vpc.public_subnets[0]
  private_ips       = ["192.168.1.50"]
  security_groups   = [module.NAT_SG.security_group_id]
  source_dest_check = false

  tags = {
    Name = "NAT_Instance_ENI"
  }
}

# NAT Instance 
resource "aws_instance" "NAT_Instance" {
  ami           = "ami-00295862c013bede0"
  instance_type = "t2.micro"
  depends_on    = [aws_network_interface.NAT_ENI]

  network_interface {
    network_interface_id = aws_network_interface.NAT_ENI.id
    device_index         = 0
  }

  tags = {
    Name = "NAT_Instance"
  }
}

# NAT Instance ENI EIP
resource "aws_eip" "NAT_Instance_eip" {
  network_interface = aws_network_interface.NAT_ENI.id
  tags = {
    Name = "NAT_EIP"
  }
  depends_on = [aws_network_interface.NAT_ENI, aws_instance.NAT_Instance]
}

# Private Subnet Routing Table ( dest: NAT Instance ENI )
data "aws_route_table" "private_1" {
  subnet_id  = module.vpc.private_subnets[0]
  depends_on = [module.vpc]
}

data "aws_route_table" "private_2" {
  subnet_id  = module.vpc.private_subnets[1]
  depends_on = [module.vpc]
}

resource "aws_route" "private_subnet_1" {
  route_table_id         = data.aws_route_table.private_1.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.NAT_ENI.id
  depends_on             = [module.vpc, aws_instance.NAT_Instance]
}

resource "aws_route" "private_subnet_2" {
  route_table_id         = data.aws_route_table.private_2.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.NAT_ENI.id
  depends_on             = [module.vpc, aws_instance.NAT_Instance]
}