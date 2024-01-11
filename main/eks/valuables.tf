locals {
  cluster_name    = "my_eks"
  cluster_version = "1.27"
  cluster_admin   = data.aws_iam_user.EKS_Admin_ID.user_id
  tags = {
    cluster_name = "my_eks"
  }
  vpc_id  = data.terraform_remote_state.vpc_remote_data.outputs.vpc_id
  subnets = data.terraform_remote_state.vpc_remote_data.outputs.private_subnets
}