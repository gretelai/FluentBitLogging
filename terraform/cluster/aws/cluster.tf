# Create the Cluster
##############################################################################################

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    security_group_ids     = [aws_security_group.cluster_group.id]
    subnet_ids             = [aws_subnet.subnet_uno.id, aws_subnet.subnet_dos.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
  ]
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name       = aws_eks_cluster.cluster.name
}

data "http" "wait_for_cluster" {
  url            = format("%s/healthz", aws_eks_cluster.cluster.endpoint)
  ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  timeout        = 300
}
