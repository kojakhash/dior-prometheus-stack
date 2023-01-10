---
prometheus:
  ingress:
    enabled: true
    ingressClassName: nginx-tools
    annotations:
      nginx.ingress.kubernetes.io/auth-url: https://auth-okta.ppd-aks-tools.christiandior.com/oauth2/auth
      nginx.ingress.kubernetes.io/auth-signin: https://auth-okta.ppd-aks-tools.christiandior.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    hosts:
      - prometheus.ppd-aks-tools.christiandior.com
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - prometheus.ppd-aks-tools.christiandior.com
        secretName: cert-christiandior-com
  prometheusSpec:
    externalLabels:
      cluster: ppd-dmz
    externalUrl: https://prometheus.ppd-aks-tools.christiandior.com
    remoteWrite:
      - url: https://mimir-aks-weu-dmz-ppd.aks.eu.dior.fashion/api/v1/push
        remoteTimeout: 30s
        tlsConfig:
          insecureSkipVerify: true
    resources:
      requests:
        cpu: 500m
        memory: 16Gi
      limits:
        memory: 16Gi
    tolerations:
      - key: memory_intensive
        operator: Equal
        value: "true"
        effect: NoSchedule
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
              - key: beta.kubernetes.io/os
                operator: In
                values:
                  - linux
              - key: workload
                operator: In
                values:
                  - memory_intensive

alertmanager:
  ingress:
    enabled: true
    ingressClassName: nginx-tools
    annotations:
      nginx.ingress.kubernetes.io/auth-url: https://auth-okta.ppd-aks-tools.christiandior.com/oauth2/auth
      nginx.ingress.kubernetes.io/auth-signin: https://auth-okta.ppd-aks-tools.christiandior.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    hosts:
      - alertmanager.ppd-aks-tools.christiandior.com
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - alertmanager.ppd-aks-tools.christiandior.com
        secretName: cert-christiandior-com
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
      # FIXME
      receiver: "slack"
      repeat_interval: 12h
      routes:
        - matchers:
            - alertname=~"Watchdog|KubeletTooManyPods|KubeCPUOvercommit|CPUThrottlingHigh|KubeAPIErrorBudgetBurn|InfoInhibitor|KubeClientCertificateExpiration"
          receiver: "null"
    receivers:
      - name: "null"
      - name: "slack"
        slack_configs:
          - send_resolved: true
            channel: "#kubernetes-ppd-dmz-events"
            title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] Monitoring Event Notification'
            text: |-
              {{ range .Alerts }}
                *Alert:* `{{ .Labels.severity }}` - {{ .Labels.alertname }} - {{ .Annotations.summary }}
                *Description:* {{ .Annotations.description }}
                *Graph:* <{{ .GeneratorURL }}|:chart_with_upwards_trend:> *Runbook:* <{{ .Annotations.runbook }}|:spiral_note_pad:>
                *Details:*
                {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
                {{ end }}
              {{ end }}
  alertmanagerSpec:
    externalUrl: https://alertmanager.ppd-aks-tools.christiandior.com

grafana:
  ingress:
    enabled: true
    ingressClassName: nginx-tools
    annotations:
      nginx.ingress.kubernetes.io/auth-url: https://auth-okta.ppd-aks-tools.christiandior.com/oauth2/auth
      nginx.ingress.kubernetes.io/auth-signin: https://auth-okta.ppd-aks-tools.christiandior.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    hosts:
      - grafana.ppd-aks-tools.christiandior.com
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - grafana.ppd-aks-tools.christiandior.com
        secretName: cert-christiandior-com
