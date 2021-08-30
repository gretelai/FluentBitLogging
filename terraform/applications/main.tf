##############################################################################################
# Inputs
##############################################################################################

# Connect to the cluster to launch applications.
################################################

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

# Application specific inputs.
##############################

variable "aws_region" {
  type        = string
  description = "Namespace in which to run FluentBit"
}

variable "dummy_namespace" {
  type        = string
  description = "Namespace in which to run FluentBit"
}

variable "dummy_service_account" {
  type        = string
  description = "Namespace in which to run FluentBit"
}

variable "logging_namespace" {
  type        = string
  description = "Namespace in which to run FluentBit"
}

variable "logging_service_account" {
  type        = string
  description = "Namespace in which to run FluentBit"
}

##############################################################################################
# Outputs
##############################################################################################

# None

##############################################################################################
# Module
##############################################################################################

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = var.cluster_ca
  token                  = var.cluster_token
}

provider "helm" {
  kubernetes {
    host = var.cluster_endpoint
    cluster_ca_certificate = var.cluster_ca
    token = var.cluster_token
  }
}

# Create a dummy deployment in Kubernetes.
##############################################################################################

resource "kubernetes_deployment" "dummy_deployment" {
  metadata {
    name = "dummy-deployment"
    namespace = var.dummy_namespace
    labels = {
      app = "dummy"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "dummy"
      }
    }
    template {
      metadata {
        labels = {
          app = "dummy"
        }
      }
      spec {
        service_account_name = var.dummy_service_account
        container {
          name = "dummy"
          image = "busybox"
          command = ["/bin/sh","-c", "while true; do echo hello! >>/dev/stderr; sleep 1; done"]
        }
      }
    }
  }
}

# Use Helm to create our FluentBit Daemonset.
##############################################################################################

resource "helm_release" "fluent_bit_daemonset" {
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.15.15"

  name       = "fluent-bit"
  namespace  = var.logging_namespace
  cleanup_on_fail = true

  values = [
    templatefile("${path.module}/templates/fluent-bit.yaml", {
      image_version        = 1.8
      service_account_name = var.logging_service_account,
      region               = var.aws_region,
    }),
  ]
}