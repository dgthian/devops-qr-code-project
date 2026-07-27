########################################
# VPC
########################################

resource "aws_vpc" "main" {

  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"

    "kubernetes.io/cluster/devops-capstone-project" = "shared"
  }
}


########################################
# Public Subnets
########################################

resource "aws_subnet" "subnet_1" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.0.0/20"

  availability_zone = "us-east-1b"

  map_public_ip_on_launch = true

  tags = {
    Name = "eks-public-subnet-1"

    "kubernetes.io/role/elb" = "1"

    "kubernetes.io/cluster/devops-capstone-project" = "shared"
  }
}


resource "aws_subnet" "subnet_2" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.16.0/20"

  availability_zone = "us-east-1c"

  map_public_ip_on_launch = true

  tags = {
    Name = "eks-public-subnet-2"

    "kubernetes.io/role/elb" = "1"

    "kubernetes.io/cluster/devops-capstone-project" = "shared"
  }
}


########################################
# Internet Gateway
########################################

resource "aws_internet_gateway" "internet_gw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "eks-internet-gateway"
  }
}


########################################
# Public Route Table
########################################

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.main.id


  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.internet_gw.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  tags = {

    Name = "eks-public-route-table"
  }
}


########################################
# Route Table Associations
########################################

resource "aws_route_table_association" "subnet_1" {

  subnet_id = aws_subnet.subnet_1.id

  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "subnet_2" {

  subnet_id = aws_subnet.subnet_2.id

  route_table_id = aws_route_table.public.id
}


########################################
# EKS Cluster
########################################
module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"


  name = "devops-capstone-project"

  kubernetes_version = "1.33"

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

  endpoint_private_access = false

   # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id = aws_vpc.main.id

  subnet_ids = [
    aws_subnet.subnet_1.id,
    aws_subnet.subnet_2.id 
  ]

  control_plane_subnet_ids = [
    aws_subnet.subnet_1.id,
    aws_subnet.subnet_2.id 
  ]


  eks_managed_node_groups = {
    green = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 10
      desired_size = 2
    }
}
}