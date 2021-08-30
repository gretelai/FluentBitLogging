# Resources for our FluentBit application in our logging namespace.
##############################################################################################

resource "kubernetes_namespace" "logging_namespace" {
  metadata {
    annotations = {
      name = var.logging_namespace
    }
    name = var.logging_namespace
  }
}

resource "kubernetes_network_policy" "logging_network_policy" {
  depends_on = [kubernetes_namespace.logging_namespace]

  metadata {
    name = "${var.logging_namespace}-network-policy"
    namespace = var.logging_namespace
  }

  spec {
    policy_types = [
      "Ingress",
      "Egress"]

    # Applies to all pods in the logging namespace.
    pod_selector {}

    # Block all Ingress with no rule.

    # Allow all Egress
    egress {}
  }
}

resource "kubernetes_service_account" "logging_service_account" {
  metadata {
    name = "${var.logging_namespace}-service-account"
    namespace = var.logging_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = var.logging_role
    }
  }
}
