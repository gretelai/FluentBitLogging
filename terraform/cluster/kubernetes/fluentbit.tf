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
  metadata {
    name = "${var.logging_namespace}-network-policy"
    namespace = kubernetes_namespace.logging_namespace.metadata.0.name
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
    namespace = kubernetes_namespace.logging_namespace.metadata.0.name
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "meta.helm.sh/release-namespace" = kubernetes_namespace.logging_namespace.metadata.0.name
      "meta.helm.sh/release-name" = "fluent-bit"
      "eks.amazonaws.com/role-arn" = var.logging_role
    }
  }
}
