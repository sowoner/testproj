# AWS EKS Cluster Data Source
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

# AWS EKS Cluster Auth Data Source
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# AWS EKS Cluster
data "aws_iam_user" "EKS_Admin_ID" {
  user_name = "admin"
}

#vpc_remote_data
data "terraform_remote_state" "vpc_remote_data" {
  backend = "s3"
  config = {
    bucket  = "myterraform-bucket-state-project-pkh"
    key     = "vpc/terraform.tfstate"
    profile = "admin_user"
    region  = "ap-northeast-2"
  }
}