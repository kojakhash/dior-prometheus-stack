---
prometheus:
  ingress:
    enabled: true
    ingressClassName: nginx-tools
    annotations:
      nginx.ingress.kubernetes.io/auth-url: https://auth-okta.aks-tools.christiandior.com/oauth2/auth
      nginx.ingress.kubernetes.io/auth-signin: https://auth-okta.aks-tools.christiandior.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    hosts:
      - prometheus.aks-tools.christiandior.com
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - prometheus.aks-tools.christiandior.com
        secretName: cert-christiandior-com
  prometheusSpec:
    externalLabels:
      cluster: prd-dmz
    externalUrl: https://prometheus.aks-tools.christiandior.com
    resources:
      requests:
        cpu: 2000m
        memory: 32Gi
      limits:
        memory: 32Gi
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
      nginx.ingress.kubernetes.io/auth-url: https://auth-okta.aks-tools.christiandior.com/oauth2/auth
      nginx.ingress.kubernetes.io/auth-signin: https://auth-okta.aks-tools.christiandior.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    hosts:
      - alertmanager.aks-tools.christiandior.com
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - alertmanager.aks-tools.christiandior.com
        secretName: cert-christiandior-com

  # https://prometheus.io/docs/alerting/latest/configuration/#configuration-file
  #
  # Show routes:
  #   amtool config routes show --config.file=/etc/alertmanager/config/alertmanager.yaml
  #
  # Test imaginary alert:
  #   amtool config routes test --config.file=/etc/alertmanager/config/alertmanager.yaml --tree --verify.receivers=slack-frontendeco-alerts severity=warning alertname=PodRestartTooOften namespace=ns-newlook-catalog
  #   amtool config routes test --config.file=/etc/alertmanager/config/alertmanager.yaml --tree --verify.receivers=opsgenie-onedior severity=critical alertname=Test namespace=ns-newlook-catalog
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
      receiver: "slack"
      repeat_interval: 12h
      routes:
        - matchers:
            - alertname="Watchdog"
          repeat_interval: 60s
          receiver: "opsgenie-onedior-heartbeat"
        - matchers:
            - alertname=~"KubeAPIErrorBudgetBurn|InfoInhibitor|KubeClientCertificateExpiration"
          receiver: "null"
        - matchers:
            - namespace!~"elastic-kafka|fluentd-kafka|rabbitmq-system|ns-bespoke-(.*)|ns-digitalcard-(.*)"
            - severity="critical"
          receiver: "opsgenie-onedior"
    receivers:
      - name: "null"
      - name: "slack"
        slack_configs:
          - send_resolved: true
            channel: "#kubernetes-prd-dmz-events"
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
      # basicAuth should work but Prometheus Operator introduced a new check
      # that silently skips the Basic Auth in case either username or password
      # is not defined. Which I guess makes sense in most cases but OpsGenie
      # auth does expect an empty username.
      # https://github.com/prometheus-operator/prometheus-operator/issues/3970
      - name: "opsgenie-onedior-heartbeat"
        webhook_configs:
          - url: https://api.eu.opsgenie.com/v2/heartbeats/watchdog-prd-dmz/ping?apiKey=${opsgenie_api_key}
            send_resolved: true
      - name: "opsgenie-onedior"
        opsgenie_configs:
          - send_resolved: true
  alertmanagerSpec:
    externalUrl: https://alertmanager.aks-tools.christiandior.com

grafana:
  persistence:
    enabled: false
  ingress:
    enabled: true
    ingressClassName: nginx-tools
    annotations:
      nginx.ingress.kubernetes.io/auth-url: https://auth-okta.aks-tools.christiandior.com/oauth2/auth
      nginx.ingress.kubernetes.io/auth-signin: https://auth-okta.aks-tools.christiandior.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    hosts:
      - grafana.aks-tools.christiandior.com
    paths:
      - /
    pathType: Prefix
    tls:
      - hosts:
          - grafana.aks-tools.christiandior.com
        secretName: cert-christiandior-com
