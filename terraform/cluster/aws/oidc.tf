# Set up the authenticator which will hand out our IAM roles within the cluster.
# If you want your service accounts to have IAM roles, then you need one of THEEEEEEEEZ.
##############################################################################################

data "tls_certificate" "eks_oidc_issuer" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc_issuer.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# Create a configmap for authorization.
# https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
##############################################################################################

provider "kubernetes" {
  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

resource "kubernetes_config_map" "aws_auth" {
  depends_on = [data.http.wait_for_cluster]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  data = {
    mapRoles = <<ROLES
- rolearn: ${aws_iam_role.eks_admin.arn}
  username: eks-admin
  groups:
  - system:masters
- rolearn: ${aws_iam_role.node_role.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
  - system:bootstrappers
  - system:nodes
ROLES
  }
}
