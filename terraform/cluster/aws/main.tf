##############################################################################################
# Inputs
##############################################################################################

variable "cluster_name" {
  type        = string
  description = "The environment identifier. Eg dev, prod, staging"
}

variable "node_count" {
  type        = number
  description = "The number of nodes to create in the cluster"
  default = 1
}

variable "node_type" {
  type        = string
  description = "The type of EC2 instance to use for our nodes."
  default = "t3.medium"
}

##############################################################################################
# Outputs
##############################################################################################

output "name" {
  description = "The environment identifier. Eg dev, prod, staging"
  value = aws_eks_cluster.cluster.name
}

output "endpoint" {
  description = "Endpoint to connect to the EKS cluster."
  value = aws_eks_cluster.cluster.endpoint
}

output "ca" {
  description = "CA certificate to use when connecting to the cluster."
  value = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
}

output "cluster_token" {
  description = "Role to use when creating our applications in the cluster."
  value = data.aws_eks_cluster_auth.cluster_auth.token
}

output "dummy_role" {
  description = "Role to use when creating our applications in the cluster."
  value = aws_eks_node_group.node_group.node_role_arn
}

output "logging_role" {
  description = "Role to use when creating our applications in the cluster."
  value = aws_eks_node_group.node_group.node_role_arn
}

##############################################################################################
# Module
##############################################################################################

terraform {
  required_providers {
    aws        = ">= 3.47.0"
    kubernetes = ">= 2.3.2"
    http = {
      source  = "terraform-aws-modules/http"
      version = ">= 2.4.1"
    }
  }
}
