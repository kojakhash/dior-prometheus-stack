---
prometheus:
  ingress:
    enabled: true
    ingressClassName: nginx-tools
    hosts:
      - prometheus.nonprd-aks-tools.christiandior.com
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - prometheus.nonprd-aks-tools.christiandior.com
        secretName: cert-christiandior-com
  prometheusSpec:
    externalLabels:
      cluster: nonprd-dmz
    externalUrl: https://prometheus.nonprd-aks-tools.christiandior.com
    resources:
      requests:
        cpu: 500m
        memory: 8Gi
      limits:
        memory: 8Gi

alertmanager:
  ingress:
    enabled: true
    ingressClassName: nginx-tools
    hosts:
      - alertmanager.nonprd-aks-tools.christiandior.com
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - alertmanager.nonprd-aks-tools.christiandior.com
        secretName: cert-christiandior-com
  # https://prometheus.io/docs/alerting/latest/configuration/#configuration-file
  #
  # Show routes:
  #   amtool config routes show --config.file=/etc/alertmanager/config/alertmanager.yaml
  #
  # Test imaginary alert:
  #   amtool config routes test --config.file=/etc/alertmanager/config/alertmanager.yaml --tree --verify.receivers=slack-frontendeco-alerts severity=warning alertname=PodRestartTooOften namespace=ns-newlook-catalog
  #
  # Simulating an alert:
  #   amtool alert add --alertmanager.url=http://127.0.0.1:9093 this-is-a-test-alert severity=warning namespace=ns-newlook-catalog alertname=PodRestartTooOften
  #   amtool alert add --alertmanager.url=http://127.0.0.1:9093 this-is-a-test-alert severity=warning alertname=Test
  #
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by:
        - alertname
        - severity
      group_interval: 5m
      group_wait: 30s
      # FIXME
      receiver: "slack"
      repeat_interval: 12h
      routes:
        - matchers:
            - alertname=~"Watchdog|KubeletTooManyPods|KubeCPUOvercommit|CPUThrottlingHigh|KubeAPIErrorBudgetBurn|InfoInhibitor|KubeClientCertificateExpiration"
          receiver: "null"
        - matchers:
            - alertname=~"PodRestartTooOften|PodRestartTooOftenCritical|KubePodCrashLooping|KubernetesContainerOomKilled"
            - namespace=~"newlook-(.*)|ns-newlook-(.*)"
          receiver: "slack-frontendeco-alerts"
    receivers:
      - name: "null"
  alertmanagerSpec:
    externalUrl: https://alertmanager.nonprd-aks-tools.christiandior.com

