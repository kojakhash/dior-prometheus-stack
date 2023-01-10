---
prometheus:
  ingress:
    enabled: false
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    ruleSelectorNilUsesHelmValues: false
    probeSelectorNilUsesHelmValues: false
    walCompression: true
    image:
      repository: acrrootweuprd.azurecr.io/prometheus/prometheus
    resources:
      requests:
        cpu: 200m
        memory: 2Gi
      limits:
        memory: 2Gi
    retention: 30d
    retentionSize: 500GiB
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes:
            - "ReadWriteOnce"
          storageClassName: managed-csi-premium-zrs
          resources:
            requests:
              storage: 512Gi
    nodeSelector:
      kubernetes.io/os: linux

alertmanager:
  enabled: true
  ingress:
    enabled: false
  alertmanagerSpec:
    image:
      repository: acrrootweuprd.azurecr.io/prometheus/alertmanager
    storage:
      volumeClaimTemplate:
        spec:
          accessModes:
            - "ReadWriteOnce"
          storageClassName: managed-csi-premium-zrs
          resources:
            requests:
              storage: 16Gi
    resources:
      requests:
        cpu: 100m
        memory: 512Mi
      limits:
        memory: 512Mi
    nodeSelector:
      kubernetes.io/os: linux

grafana:
  downloadDashboardsImage:
    repository: acrrootweuprd.azurecr.io/curlimages/curl
  # Ideally, the persistance should not be used:
  # - dashboards and datasources should be created with configmaps
  # - users are authenticated with oauth provider like github
  # However, it can be handy to persist a dashboard while creating it, before exporting it to configmap
  persistence:
    enabled: false
  # https://github.com/helm/charts/issues/10622
  # Enable Anonymous access as we are protecting Grafana with Github OAuth using the Ingress annotation
  # For Anonymous user, it is read-only access with possibility to sign in (e.g. admin or other users).
  grafana.ini:
    users:
      # When set to true, users with Viewer can also make transient dashboard edits,
      # meaning they can modify panels and queries but not save the changes (nor create new dashboards)
      # https://grafana.com/docs/grafana/latest/permissions/organization_roles/#viewer-role
      viewers_can_edit: true
    auth:
      disable_login_form: false
      disable_signout_menu: false
    auth.anonymous:
      enabled: true
      org_role: Viewer
    dataproxy:
      logging: true
      timeout: 120  # 120s (default is 30s)
  initChownData:
    image:
      repository: acrrootweuprd.azurecr.io/busybox
      tag: stable
  image:
    repository: acrrootweuprd.azurecr.io/grafana/grafana
    tag: 9.1.6
  ingress:
    enabled: false
  resources:
    requests:
      cpu: 200m
      memory: 1Gi
    limits:
      memory: 1Gi
  sidecar:
    image:
      repository: acrrootweuprd.azurecr.io/kiwigrid/k8s-sidecar
    dashboards:
      searchNamespace: ALL
      multicluster:
        global:
          enabled: true
        etcd:
          enabled: true
    datasources:
      searchNamespace: ALL
  plugins:
    - grafana-piechart-panel
    - grafana-polystat-panel
    - grafana-worldmap-panel
  nodeSelector:
    kubernetes.io/os: linux

kube-state-metrics:
  image:
    repository: acrrootweuprd.azurecr.io/kube-state-metrics/kube-state-metrics

prometheus-node-exporter:
  image:
    repository: acrrootweuprd.azurecr.io/prometheus/node-exporter

prometheusOperator:
  admissionWebhooks:
    patch:
      image:
        repository: acrrootweuprd.azurecr.io/ingress-nginx/kube-webhook-certgen
        tag: v1.1.1
        sha: ""
  image:
    repository: acrrootweuprd.azurecr.io/prometheus-operator/prometheus-operator
  prometheusConfigReloader:
    image:
      repository: acrrootweuprd.azurecr.io/prometheus-operator/prometheus-config-reloader
  nodeSelector:
    kubernetes.io/os: linux

kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
kubeEtcd:
  enabled: false
kubeProxy:
  enabled: false
