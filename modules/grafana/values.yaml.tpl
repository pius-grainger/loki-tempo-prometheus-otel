adminUser: admin
adminPassword: "${admin_password}"

persistence:
  enabled: ${persistence_enabled}
  size: ${persistence_size}

# ──────────────────────────────────────────────
# Dashboard sidecar — watches ConfigMaps with label grafana_dashboard=1
# ──────────────────────────────────────────────
sidecar:
  dashboards:
    enabled: true
    label: grafana_dashboard
    labelValue: "1"
    folder: /tmp/dashboards
    searchNamespace: ALL

# ──────────────────────────────────────────────
# Datasource provisioning with full cross-linking
# ──────────────────────────────────────────────
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        uid: prometheus
        type: prometheus
        url: ${prometheus_url}
        access: proxy
        isDefault: true
        editable: false

      - name: Loki
        uid: loki
        type: loki
        url: ${loki_url}
        access: proxy
        editable: false
        jsonData:
          derivedFields:
            - datasourceUid: tempo
              matcherRegex: '"traceID":"(\\w+)"'
              name: TraceID
              url: "$${__value.raw}"
              urlDisplayLabel: "View Trace"

      - name: Tempo
        uid: tempo
        type: tempo
        url: ${tempo_url}
        access: proxy
        editable: false
        jsonData:
          tracesToLogsV2:
            datasourceUid: loki
            spanStartTimeShift: "-1h"
            spanEndTimeShift: "1h"
            filterByTraceID: true
            filterBySpanID: false
          tracesToMetrics:
            datasourceUid: prometheus
            spanStartTimeShift: "-1h"
            spanEndTimeShift: "1h"
          serviceMap:
            datasourceUid: prometheus
          nodeGraph:
            enabled: true
          lokiSearch:
            datasourceUid: loki

%{ if ingress_enabled }
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
  hosts:
    - ${ingress_host}
%{ endif }
