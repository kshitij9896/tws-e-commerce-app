# =====================================================================
# 1. AWS REGION & VPC DETAILS
# =====================================================================
output "region" {
  description = "The AWS region where resources are created"
  value       = try(local.region, "ap-south-1")
}

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = try(module.vpc.vpc_id, "VPC Module mismatch")
}

# =====================================================================
# 2. CUSTOM EKS CLUSTER OUTPUTS (Mapped to your exact eks.tf)
# =====================================================================
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

# =====================================================================
# 3. JENKINS INSTANCE PUBLIC IP
# =====================================================================
output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = try(aws_instance.testinstance.public_ip, "Resource name mismatch")
}

# =====================================================================
# 4. DATA BLOCK + OUTPUT FOR EKS NODES PUBLIC IPs
# =====================================================================
data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:kubernetes.io/cluster/${aws_eks_cluster.this.name}"
    values = ["owned"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  # Makes sure the data block waits until the node group is actually built
  depends_on = [aws_eks_node_group.tws_demo_ng]
}

output "eks_node_group_public_ips" {
  description = "Public IPs of the EKS node group instances"
  value       = data.aws_instances.eks_nodes.public_ips
}