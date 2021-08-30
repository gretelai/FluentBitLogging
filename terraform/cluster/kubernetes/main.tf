##############################################################################################
# Inputs
##############################################################################################

variable "cluster_name" {
  type        = string
  description = "The environment identifier. Eg dev, prod, staging"
}

variable "cluster_endpoint" {
  type        = string
  description = "Endpoint to connect to the EKS cluster."
}

variable "cluster_ca" {
  type        = string
  description = "CA certificate to use when connecting to the cluster."
}

variable "cluster_token" {
  type        = string
  description = "Token to use to authenticate with the cluster."
}

variable "dummy_namespace" {
  type        = string
  description = "Role to use when creating our applications in the cluster."
}

variable "dummy_role" {
  type        = string
  description = "Role to use when creating our applications in the cluster."
}

variable "logging_namespace" {
  type        = string
  description = "Role to use when creating our applications in the cluster."
}

variable "logging_role" {
  type        = string
  description = "Role to use when creating our applications in the cluster."
}

##############################################################################################
# Outputs
##############################################################################################

# None

##############################################################################################
# Module
##############################################################################################

terraform {
  required_providers {
    kubernetes = ">= 2.3.2"
  }
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = var.cluster_ca
  token                  = var.cluster_token
}