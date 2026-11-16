# =====================================================================
# 1. IAM ROLE & POLICY FOR THE EKS CONTROL PLANE
# =====================================================================
resource "aws_iam_role" "eks_cluster_role" {
  name = "tws-eks-cluster-role-native"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# =====================================================================
# 2. NATIVE EKS CLUSTER CONTROL PLANE
# =====================================================================
resource "aws_eks_cluster" "this" {
  name     = "tws-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    endpoint_public_access = true
    subnet_ids             = module.vpc.public_subnets 
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# =====================================================================
# 3. IAM ROLE & POLICIES FOR WORKER NODES
# =====================================================================
resource "aws_iam_role" "eks_node_role" {
  name = "tws-eks-node-role-native"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# =====================================================================
# 4. NATIVE AWS EKS MANAGED NODE GROUP
# =====================================================================
resource "aws_eks_node_group" "tws_demo_ng" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "tws-demo-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = module.vpc.public_subnets

  capacity_type  = "ON_DEMAND"
  instance_types = [var.instance_type]
  disk_size      = 35

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  tags = {
    Name        = "tws-demo-ng"
    Environment = "dev"
    ExtraTag    = "e-commerce-app"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy
  ]
}

# =====================================================================
# 5. ALLOW INBOUND TO THE APP NODEPORT ON THE EKS NODES
# =====================================================================
resource "aws_security_group_rule" "nodeport_app" {
  type              = "ingress"
  description       = "EasyShop NodePort"
  from_port         = 30000
  to_port           = 30000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # tighten to your IP (x.x.x.x/32) if you like
  security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

