variable "zone" {
  type = string
}

variable "environment" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "helm_max_history" {
  type    = number
  default = 5
}
variable "location_suffix" {
  default = "weu"

}
variable "helm_rollback_on_failure" {
  type    = bool
  default = true
}
variable "secret" {
  type    = list(string)
  default = []
}
variable "helm_chart_prometheus-stack" {
  type = object({
    repository = string
    chart      = string
    version    = string
  })
  default = {
    # https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/Chart.yaml
    repository = "https://prometheus-community.github.io/helm-charts"
    chart      = "kube-prometheus-stack"
    version    = "31.0.0"
  }
}
variable "interne_ingress" {
  type    = bool
  default = false
}