##############################################################################################
# Inputs
##############################################################################################

variable "cluster_name" {
  type        = string
  description = "The name of the cluster to create in EKS"
}

variable "node_count" {
  type        = number
  description = "The number of nodes to create in the cluster"
  default = 1
}

variable "node_type" {
  type        = string
  description = "The type of EC2 instance to use for our nodes."
  default = "m4.medium"
}

variable "dummy_namespace" {
  type        = string
  description = "Role to use when creating our applications in the cluster."
}

variable "logging_namespace" {
  type        = string
  description = "Role to use when creating our applications in the cluster."
}


##############################################################################################
# Outputs
##############################################################################################

output "name" {
  description = "The name of the cluster created."
  value = module.aws.name
}

output "endpoint" {
  description = "Endpoint to connect to the EKS cluster."
  value = module.aws.endpoint
}

output "ca" {
  description = "CA certificate to use when connecting to the cluster."
  value = module.aws.ca
}

output "cluster_token" {
  description = "Role to use when creating our applications in the cluster."
  value = module.aws.cluster_token
}

output "dummy_namespace" {
  description = "Name of the namespace created to hold out dummy application."
  value = module.kubernetes.dummy_namespace
}

output "dummy_service_account" {
  description = "Name of the service account erted to run out dummy application."
  value = module.kubernetes.dummy_service_account
}

output "logging_namespace" {
  description = "Name of the namespace created to hold our logging application."
  value = module.kubernetes.logging_namespace
}

output "logging_service_account" {
  description = "Name of the service account created to run our logging application."
  value = module.kubernetes.logging_service_account
}

##############################################################################################
# Module
##############################################################################################

# Launch our FluentBit Daemonset in the cluster along with a dummy application.
module "aws" {
  source  = "./aws"

  cluster_name = var.cluster_name
  node_count = 1
  node_type = "t3.medium"
}

module "kubernetes" {
  source  = "./kubernetes"

  dummy_namespace = var.dummy_namespace
  dummy_role = module.aws.dummy_role

  logging_namespace = var.logging_namespace
  logging_role = module.aws.logging_role

  cluster_name = module.aws.name
  cluster_endpoint = module.aws.endpoint
  cluster_ca = module.aws.ca
  cluster_token = module.aws.cluster_token
}