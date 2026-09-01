
# VPC

resource "aws_vpc" "devsecops" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# Availability Zones

data "aws_availability_zones" "available" {
  state = "available"
}

# Public Subnets

resource "aws_subnet" "public" {
  count = 2

  vpc_id = aws_vpc.devsecops.id

  cidr_block = element(
    ["10.0.1.0/24", "10.0.2.0/24"],
    count.index
  )

  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"

    "kubernetes.io/role/elb" = "1"

    Environment = var.environment
  }
}

# Private Subnets

resource "aws_subnet" "private" {
  count = 2

  vpc_id = aws_vpc.devsecops.id

  cidr_block = element(
    ["10.0.11.0/24", "10.0.12.0/24"],
    count.index
  )

  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"

    "kubernetes.io/role/internal-elb" = "1"

    Environment = var.environment
  }
}

# Internet Gateway

resource "aws_internet_gateway" "devsecops" {
  vpc_id = aws_vpc.devsecops.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Route Table

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.devsecops.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devsecops.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Public Route Table Associations

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id = aws_subnet.public[count.index].id

  route_table_id = aws_route_table.public.id
}


# Elastic IPs for NAT Gateways

resource "aws_eip" "nat" {
  count = 1

  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }
}


# NAT Gateways

resource "aws_nat_gateway" "devsecops" {
  count = 1

  allocation_id = aws_eip.nat[count.index].id

  subnet_id = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}"
  }

  depends_on = [
    aws_internet_gateway.devsecops
  ]
}

# Private Route Tables

resource "aws_route_table" "private" {
  count = 2

  vpc_id = aws_vpc.devsecops.id

  route {
    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.devsecops[0].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  }
}

# Private Route Table Associations

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id = aws_subnet.private[count.index].id

  route_table_id = aws_route_table.private[count.index].id
}


# ================================
# EKS Cluster IAM Role
# ================================

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-eks-cluster-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


# ================================
# EKS Cluster
# ================================

resource "aws_eks_cluster" "devsecops" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}


# ================================
# EKS Worker Node IAM Role
# ================================

resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-eks-node-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# ================================
# EKS Managed Node Group
# ================================

resource "aws_eks_node_group" "devsecops" {
  cluster_name = aws_eks_cluster.devsecops.name

  node_group_name = "${var.project_name}-nodes"

  node_role_arn = aws_iam_role.eks_nodes.arn

  subnet_ids = aws_subnet.private[*].id

  instance_types = [var.node_instance_type]

  capacity_type = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
  ]

  tags = {
    Name        = "${var.project_name}-node"
    Environment = var.environment
  }
}


# ================================
# EKS OIDC Provider
# ================================

data "tls_certificate" "eks" {
  url = aws_eks_cluster.devsecops.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.devsecops.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks.certificates[0].sha1_fingerprint
  ]

  tags = {
    Name        = "${var.project_name}-eks-oidc"
    Environment = var.environment
  }
}


# ==========================================
# EBS CSI Driver IAM Policy
# ==========================================

resource "aws_iam_role" "ebs_csi" {
  name = "${var.project_name}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "${replace(
              aws_iam_openid_connect_provider.eks.url,
              "https://",
              ""
            )}:aud" = "sts.amazonaws.com"

            "${replace(
              aws_iam_openid_connect_provider.eks.url,
              "https://",
              ""
            )}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ebs-csi-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ==========================================
# EKS EBS CSI Add-on
# ==========================================

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.devsecops.name

  addon_name = "aws-ebs-csi-driver"

  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi
  ]

  tags = {
    Name        = "${var.project_name}-ebs-csi"
    Environment = var.environment
  }
}


# ==========================================
# Argo CD
# ==========================================

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  depends_on = [
    aws_eks_node_group.devsecops
  ]
}