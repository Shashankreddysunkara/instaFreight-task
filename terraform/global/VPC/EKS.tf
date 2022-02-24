data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

terraform {
  required_version = ">= 0.12"
  required_providers {
	kubernetes = {
		version = "~> 1.10"
	}
  random = {
		version = "~> 2.1"
	}
  local = {
		version = "~> 1.2"
	}
  null = {
		version = "~> 2.1"
	}
  template = {
		version = "~> 2.1"
	}
  aws = {
		source = "hashicorp/aws"
		version = "~> 3.74"
	}
  }
}

locals {
  cluster_name = "ops-eks-${random_string.suffix.result}"
  cluster_version = "1.21"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_version = local.cluster_version
  cluster_name    = local.cluster_name
  subnets         = aws_subnet.private.*.id

  tags = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = "${aws_vpc.terra_vpc.id}"

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.medium"
      # additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 2 
      asg_max_size                  = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id, aws_security_group.ops_consul.id,
      aws_security_group.monitor_sg.id]
    }
    # }, when there's more than one worker group, delete the previous } and replace it with this.
    # {
    #   name                          = "worker-group-2"
    #   instance_type                 = "t2.medium"
    #   additional_userdata           = "echo foo bar"
    #   additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
    #   asg_desired_capacity          = 1
    # },
  ]

  worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id, aws_security_group.ops_consul.id,
  aws_security_group.monitor_sg.id]
  map_roles  = [
    {
        rolearn  = aws_iam_role.eks-kubectl.arn
        username = "ubuntu"
        groups   = ["system:masters"]
    }
  ]
  
  # map_users                            = var.map_users
  # map_accounts                         = var.map_accounts
}
