resource "kubernetes_namespace" "k8s-namespace-prometheus-stack" {
  metadata {
    name = "prometheus-stack"
  }
}

resource "random_string" "grafana-adminPassword" {
  length  = 32
  special = true
}
# module "vault" {
#   source                = "../../modules/azure-secret-loader"
#   environment           = var.environment
#   location_suffix       = var.location_suffix
#   ressource_groupe_name = local.ressource_groupe_name
#   zone                  = var.zone
#   app_name              = "k8s"
#   secrets               = var.secret
# }

# resource "kubernetes_secret" "public_wildcard_tls_cert" {

#   count = contains(var.secret, "tls-cert-wildcard") ? 1 : 0

#   metadata {
#     name      = "cert-christiandior-com"
#     namespace = kubernetes_namespace.k8s-namespace-prometheus-stack.metadata[0].name
#     labels = {
#       wildcard = "christiandior.com"
#     }
#   }
#   type = "kubernetes.io/tls"

#   data = {
#     "tls.crt" = base64decode(module.vault.secrets["tls-cert-wildcard"].value),
#     "tls.key" = base64decode(module.vault.secrets["tls-key-wildcard"].value)
#   }
# }
resource "helm_release" "prometheus-stack" {
  name        = "prometheus-stack"
  repository  = var.helm_chart_prometheus-stack.repository
  chart       = var.helm_chart_prometheus-stack.chart
  version     = var.helm_chart_prometheus-stack.version
  namespace   = kubernetes_namespace.k8s-namespace-prometheus-stack.metadata[0].name
  max_history = var.helm_max_history
  atomic      = var.helm_rollback_on_failure
  timeout     = 1200

  values = [
    templatefile("${path.module}/helm_values/common.yaml.tpl", {}),
    templatefile("${path.module}/helm_values/${var.environment}-${var.zone}.yaml.tpl")
  ]

  set {
    name  = "grafana.adminPassword"
    value = random_string.grafana-adminPassword.result
  }

  # set {
  #   name  = "alertmanager.config.global.slack_api_url"
  #   value = module.vault.secrets["slack-hook-url"].value
  # }

  # set {
  #   name  = "alertmanager.config.global.opsgenie_api_url"
  #   value = "https://api.eu.opsgenie.com"
  # }

  # set {
  #   name  = "alertmanager.config.global.opsgenie_api_key"
  #   value = module.vault.secrets["opsgenie-api-key"].value
  # }

  set {
    name  = "kube-state-metrics.metricLabelsAllowlist"
    value = "deployments=[*],pods=[*]"
  }
}

# https://github.com/prometheus-stack/prometheus-stack/blob/master/Documentation/rbac-crd.md#aggregated-clusterroles
#
# It can be useful to aggregate permissions on the Prometheus Operator CustomResourceDefinitions to the default user-facing roles, like view, edit and admin.
#
# This grants:
#
#  - Users with view role permissions to view the Prometheus Operator CRDs within
#    their namespaces,
#  - Users with edit and admin roles permissions to create, edit and delete
#    Prometheus Operator CRDs within their namespaces.
resource "kubernetes_cluster_role" "prometheus-crd-view" {
  metadata {
    name = "prometheus-crd-view"
    labels = {
      "rbac.authorization.k8s.io/aggregate-to-admin" = true,
      "rbac.authorization.k8s.io/aggregate-to-edit"  = true,
      "rbac.authorization.k8s.io/aggregate-to-view"  = true,
    }
  }

  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["alertmanagers", "alertmanagerconfigs", "prometheuses", "prometheusrules", "servicemonitors", "podmonitors", "probes"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [
    helm_release.prometheus-stack
  ]
}

resource "kubernetes_cluster_role" "prometheus-crd-edit" {
  metadata {
    name = "prometheus-crd-edit"
    labels = {
      "rbac.authorization.k8s.io/aggregate-to-admin" = true,
      "rbac.authorization.k8s.io/aggregate-to-edit"  = true,
    }
  }

  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["alertmanagers", "alertmanagerconfigs", "prometheuses", "prometheusrules", "servicemonitors", "podmonitors", "probes"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  depends_on = [
    helm_release.prometheus-stack
  ]
}
resource "kubernetes_ingress_v1" "prometheus_ingress" {
  count = var.interne_ingress == true ? 1 : 0
  metadata {
    name = "prometheus-interne-ingress"
    namespace = kubernetes_namespace.k8s-namespace-prometheus-stack.metadata[0].name
  }
  spec {
    ingress_class_name = "nginx-tools"
    rule {
      host = "prometheus-aks-weu-${var.zone}-${var.environment}.aks.eu.dior.fashion"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "prometheus-stack-kube-prom-prometheus"
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
    tls {
      hosts = ["prometheus-aks-weu-${var.zone}-${var.environment}.aks.eu.dior.fashion"]
    }
  }
}
