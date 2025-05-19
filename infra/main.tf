module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name            = "eks-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Name = "eks-vpc"
  }
}

module "eks_cluster_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "eks-cluster-sg"
  description = "Security group for the EKS cluster"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
  egress_rules        = ["all-all"]

  tags = {
    Name = "eks-cluster-sg"
  }
}

module "eks_node_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "eks-node-sg"
  description = "Security group for the EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  
  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]

  ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.eks_cluster_sg.security_group_id
    }
  ]

  egress_rules = ["all-all"]

  tags = {
    Name = "eks-node-sg"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_security_group_id = module.eks_cluster_sg.security_group_id

  cluster_endpoint_public_access  = true  
  cluster_endpoint_public_access_cidrs = ["Your public IP"]

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    worker_group = {
      desired_size                  = 2
      max_size                      = 2
      min_size                      = 1
      instance_types                = ["t2.micro"]
      key_name                      = "ec2-access"
      additional_security_group_ids = [module.eks_node_sg.security_group_id]
    }
  }

  tags = {
    Environment = "Dev"
    Project     = "EKS-Cluster"
  }
  
}
