---
prometheus:
  ingress:
    enabled: true
    ingressClassName: nginx-tools
    annotations:
      # nginx.ingress.kubernetes.io/auth-url: https://auth-github-k8s-ppd-trust.aks.eu.dior.fashion/oauth2/auth
      # nginx.ingress.kubernetes.io/auth-signin: https://auth-github-k8s-ppd-trust.aks.eu.dior.fashion/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    hosts:
      - prometheus-aks-weu-trust-ppd.aks.eu.dior.fashion
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - prometheus-k8s-ppd-trust.aks.eu.dior.fashion
  prometheusSpec:
    externalLabels:
      cluster: ppd-trust
    externalUrl: https://prometheus-k8s-ppd-trust.aks.eu.dior.fashion
    resources:
      requests:
        cpu: 200m
        memory: 4Gi
      limits:
        memory: 4Gi
    tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"

alertmanager:
  ingress:
    enabled: true
    ingressClassName: nginx-tools
    annotations:
      # nginx.ingress.kubernetes.io/auth-url: https://auth-github-k8s-ppd-trust.aks.eu.dior.fashion/oauth2/auth
      # nginx.ingress.kubernetes.io/auth-signin: https://auth-github-k8s-ppd-trust.aks.eu.dior.fashion/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    hosts:
      - alertmanager-k8s-ppd-trust.aks.eu.dior.fashion
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - alertmanager-aks-weu-trust-ppd.aks.eu.dior.fashion
  # https://prometheus.io/docs/alerting/latest/configuration/#configuration-file
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by:
        - alertname
        - severity
      group_interval: 5m
      group_wait: 30s
      receiver: "null"
      repeat_interval: 12h
      routes:
        - matchers:
            - alertname=~"Watchdog|KubeletTooManyPods|KubeCPUOvercommit|CPUThrottlingHigh|KubeAPIErrorBudgetBurn|InfoInhibitor|KubeClientCertificateExpiration"
          receiver: "null"
    receivers:
      - name: "null"
      #- name: "slack"
      #  slack_configs:
      #    - send_resolved: true
      #      channel: "#kubernetes-ppd-trust-events"
      #      title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] Monitoring Event Notification'
      #      text: |-
      #        {{ range .Alerts }}
      #          *Alert:* `{{ .Labels.severity }}` - {{ .Labels.alertname }} - {{ .Annotations.summary }}
      #          *Description:* {{ .Annotations.description }}
      #          *Graph:* <{{ .GeneratorURL }}|:chart_with_upwards_trend:> *Runbook:* <{{ .Annotations.runbook }}|:spiral_note_pad:>
      #          *Details:*
      #          {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
      #          {{ end }}
      #        {{ end }}
  alertmanagerSpec:
    externalUrl: https://alertmanager-k8s-ppd-trust.aks.eu.dior.fashion

grafana:
  persistence:
    enabled: false
  ingress:
    enabled: true
    ingressClassName: nginx-tools
    annotations:
      # nginx.ingress.kubernetes.io/auth-url: https://auth-github-k8s-ppd-trust.aks.eu.dior.fashion/oauth2/auth
      # nginx.ingress.kubernetes.io/auth-signin: https://auth-github-k8s-ppd-trust.aks.eu.dior.fashion/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    hosts:
      - grafana-aks-weu-trust-ppd.aks.eu.dior.fashion
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - grafana-k8s-ppd-trust.aks.eu.dior.fashion
