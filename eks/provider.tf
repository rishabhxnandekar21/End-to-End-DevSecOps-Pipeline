/* Use AWS, use the terraform-admin CLI profile, and deploy into ap-south-1
   through the variable defined in variables.tf. */

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "terraform-admin"
}

data "aws_eks_cluster" "devsecops" {
  name = aws_eks_cluster.devsecops.name
}

data "aws_eks_cluster_auth" "devsecops" {
  name = aws_eks_cluster.devsecops.name
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.devsecops.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.devsecops.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.devsecops.token
  }
}