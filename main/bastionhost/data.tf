# BastionHost Key-Pair DataSource
data "aws_key_pair" "EC2-Key" {
  key_name = "EC2-key"
}

#module vpc data
data "terraform_remote_state" "vpc_remote_data" {
  backend = "s3"
  config = {
    bucket  = "myterraform-bucket-state-project-pkh"
    key     = "vpc/terraform.tfstate"
    profile = "admin_user"
    region  = "ap-northeast-2"
  }
}

#module eks_cluster data
data "terraform_remote_state" "eks_remote_data" {
  backend = "s3"
  config = {
    bucket  = "myterraform-bucket-state-project-pkh"
    key     = "eks/terraform.tfstate"
    profile = "admin_user"
    region  = "ap-northeast-2"
  }
}