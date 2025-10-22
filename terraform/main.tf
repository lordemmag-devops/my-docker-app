terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "my-docker-app-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
  
  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
}

module "eks" {
  source = "./modules/eks"
  
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  
  node_groups = var.node_groups
}

module "security" {
  source = "./modules/security"
  
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
}