# 1. Configure the Terraform AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 2. Create a VPC for our EKS Cluster
# EKS requires a dedicated Virtual Private Cloud (VPC) with public and private subnets.
# This module simplifies the creation of a production-ready VPC.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Project = var.project_name
  }
}

# 3. Create the EKS Cluster
# This module creates the EKS control plane and the worker nodes where our applications will run.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    general = {
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Project = var.project_name
  }
}

# 4. Create the S3 Bucket for the Data Lake
# This bucket will store our raw and processed datasets.
resource "aws_s3_bucket" "data_lake" {
  # Bucket names must be globally unique. Add a random suffix to avoid collisions.
  bucket = "${var.project_name}-data-lake-${random_id.suffix.hex}"

  tags = {
    Project = var.project_name
  }
}

# Add a resource to generate a random suffix for the S3 bucket name
resource "random_id" "suffix" {
  byte_length = 4
}

# 5. Create IAM Role for S3 access (to be used later)
# This creates a role that other services (like Databricks or Airflow) can assume
# to securely access our S3 bucket. We will define permissions later.
resource "aws_iam_role" "s3_access_role" {
  name = "${var.project_name}-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          # This would be updated later with the ARN of the service needing access
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project = var.project_name
  }
}