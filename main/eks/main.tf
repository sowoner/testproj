# Terraform 초기구성
terraform {
  backend "s3" {
    bucket         = "myterraform-bucket-state-project-pkh"
    key            = "eks/terraform.tfstate"
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

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

#eks resource
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.0"

  # EKS Cluster Setting(k8)
  cluster_name                    = local.cluster_name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  vpc_id                          = local.vpc_id
  subnet_ids                      = local.subnets # work node가 만들어 질 위치

  # OIDC(OpenID Connect) 구성 
  enable_irsa = true

  # EKS Worker Node 정의 ( ManagedNode방식 / Launch Template 자동 구성 )
  eks_managed_node_groups = {
    initial = {
      instance_types         = ["t3.small"]
      create_security_group  = false
      create_launch_template = false # Required Option    Required Option은 없어서는 안되므로 false 또는 공란으로 둔다
      launch_template_name   = ""    # Required Option    공란 = ""

      min_size     = 2
      max_size     = 3
      desired_size = 2

    }
  }  


  # K8s ConfigMap Object "aws_auth" 구성
  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${local.cluster_admin}:user/admin"
      username = "admin"
      groups   = ["system:masters"]
    },
  ]
}

// Private Subnet Tag ( AWS Load Balancer Controller Tag / internal )
resource "aws_ec2_tag" "private_subnet_tag" {
  for_each    = toset(data.terraform_remote_state.vpc_remote_data.outputs.private_subnets)  #(module.vpc.private_subnets)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

// Public Subnet Tag ( AWS Load Balancer Controller Tag / internet-facing )
resource "aws_ec2_tag" "public_subnet_tag" {
  for_each    = toset(data.terraform_remote_state.vpc_remote_data.outputs.public_subnets)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}




module "load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "eks-lb-controller-irsa-role"
  attach_load_balancer_controller_policy = true  # 이 Input을 기준으로 목적에 맞는 Role이 생성됨.
  
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    CreatedBy = "Terraform"
  }
  depends_on = [ module.eks ]
}

module "load_balancer_controller_targetgroup_binding_only_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "eks-lb-controller-tg-binding-only-irsa-role"
  attach_load_balancer_controller_targetgroup_binding_only_policy = true  # 이 Input을 기준으로 목적에 맞는 Role이 생성됨.

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    CreatedBy = "Terraform"
  }
  depends_on = [ module.eks ]
}