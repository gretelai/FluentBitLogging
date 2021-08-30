  ##############################################################################################
# Setup Terraform to use AWS the way we'd like.
##############################################################################################

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws        = ">= 3.53.0"
    kubernetes = ">= 2.4.1"
    tls        = ">=3.1.0"
    http = {
      source  = "terraform-aws-modules/http"
      version = ">= 2.4.1"
    }
  }
  # For a list of backends supported, including AWS S3 (example below).
  # see: https://www.terraform.io/docs/language/settings/backends/index.html
  # For demo's sake, we use the local backend configured below.
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Since we will be using AWS tooling and stacks, we need to declare it as our provider.
# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region = "us-east-2"
}

# This loads the current region.
data "aws_region" "current" {}

##############################################################################################
# Setup our cluster and FluentBit Daemonset.
##############################################################################################

# Create our EKS cluster.
module "cluster" {
  source  = "./cluster"

  cluster_name = "my-cluster"
  dummy_namespace = "dummies"
  logging_namespace = "logging"
}

# Launch our FluentBit Daemonset in the cluster along with a dummy application.
module "applications" {
  source  = "./applications"

  aws_region = data.aws_region.current.name

  dummy_namespace = "dummies"
  dummy_service_account = "dummy-service-account"

  logging_namespace = "logging"
  logging_service_account = "fluent-bit-svc-acct"

  cluster_endpoint = module.cluster.endpoint
  cluster_ca = module.cluster.ca
  cluster_token = module.cluster.cluster_token
}

