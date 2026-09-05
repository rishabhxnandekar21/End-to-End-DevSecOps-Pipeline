
# ==========================================
# AWS Load Balancer Controller IAM Policy
# ==========================================

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.project_name}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = file("${path.module}/policies/aws-load-balancer-controller-policy.json")

  tags = {
    Name        = "${var.project_name}-alb-controller-policy"
    Environment = var.environment
  }
}

# ==========================================
# AWS Load Balancer Controller IAM Role
# ==========================================

resource "aws_iam_role" "alb_controller" {
  name = "${var.project_name}-alb-controller-role"

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
            )}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-alb-controller-role"
    Environment = var.environment
  }
}

# ==========================================
# Attach ALB Controller Policy
# ==========================================

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# ==========================================
# AWS Load Balancer Controller Helm Release
# ==========================================

resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = false

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  depends_on = [
    aws_iam_role_policy_attachment.alb_controller,
    aws_eks_node_group.devsecops
  ]

  set = [
    {
      name  = "clusterName"
      value = aws_eks_cluster.devsecops.name
    },
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "vpcId"
      value = aws_vpc.devsecops.id
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.alb_controller.arn
    }
  ]
}

# ==========================================
# AWS Load Balancer Controller CRD Read RBAC
# ==========================================

resource "kubernetes_cluster_role" "alb_controller_crd_read" {
  metadata {
    name = "aws-load-balancer-controller-crd-read"
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "alb_controller_crd_read" {
  metadata {
    name = "aws-load-balancer-controller-crd-read"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.alb_controller_crd_read.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }
}

