# Resources for our dummy application in our dummy namespace.
##############################################################################################

resource "kubernetes_namespace" "dummy_namespace" {
  metadata {
    annotations = {
      name = var.dummy_namespace
    }
    name = var.dummy_namespace
  }
}

resource "kubernetes_network_policy" "dummy_network_policy" {
  depends_on = [kubernetes_namespace.dummy_namespace]

  metadata {
    name = "${var.dummy_namespace}-network-policy"
    namespace = var.dummy_namespace
  }

  spec {
    policy_types = [
      "Ingress",
      "Egress"]

    # Applies to all pods in the dummy namespace.
    pod_selector {}

    # Block all Ingress and Egress with no rule.
  }
}

resource "kubernetes_service_account" "dummy_application" {
  metadata {
    name = "${var.dummy_namespace}-service-account"
    namespace = var.dummy_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = var.dummy_role
    }
  }
}
