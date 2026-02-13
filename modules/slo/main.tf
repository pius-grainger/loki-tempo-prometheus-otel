# ──────────────────────────────────────────────
# SLI Recording Rules
# ──────────────────────────────────────────────
resource "kubernetes_manifest" "sli_recording_rules" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "sli-recording-rules"
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "prometheus"                   = "kube-prometheus"
        "role"                         = "slo"
      }
    }
    spec = {
      groups = [
        # ── Application SLIs ──────────────────────────
        {
          name     = "sli:application:availability"
          interval = "30s"
          rules = [
            # ── sample-app (Python) ───────────────────
            {
              record = "sli:app_availability:ratio_rate5m"
              expr   = "sum(rate(http_server_duration_milliseconds_count{job=\"sample-app\", http_status_code!~\"5..\"}[5m])) / sum(rate(http_server_duration_milliseconds_count{job=\"sample-app\"}[5m]))"
              labels = {
                service = "sample-app"
                slo     = "availability"
              }
            },
            {
              record = "sli:app_availability:ratio_rate30m"
              expr   = "sum(rate(http_server_duration_milliseconds_count{job=\"sample-app\", http_status_code!~\"5..\"}[30m])) / sum(rate(http_server_duration_milliseconds_count{job=\"sample-app\"}[30m]))"
              labels = {
                service = "sample-app"
                slo     = "availability"
              }
            },
            {
              record = "sli:app_availability:ratio_rate1h"
              expr   = "sum(rate(http_server_duration_milliseconds_count{job=\"sample-app\", http_status_code!~\"5..\"}[1h])) / sum(rate(http_server_duration_milliseconds_count{job=\"sample-app\"}[1h]))"
              labels = {
                service = "sample-app"
                slo     = "availability"
              }
            },
            # ── sample-app-ts (TypeScript) ────────────
            {
              record = "sli:app_availability:ratio_rate5m"
              expr   = "sum(rate(http_server_duration_milliseconds_count{job=\"sample-app-ts\", http_status_code!~\"5..\"}[5m])) / sum(rate(http_server_duration_milliseconds_count{job=\"sample-app-ts\"}[5m]))"
              labels = {
                service = "sample-app-ts"
                slo     = "availability"
              }
            },
            {
              record = "sli:app_availability:ratio_rate30m"
              expr   = "sum(rate(http_server_duration_milliseconds_count{job=\"sample-app-ts\", http_status_code!~\"5..\"}[30m])) / sum(rate(http_server_duration_milliseconds_count{job=\"sample-app-ts\"}[30m]))"
              labels = {
                service = "sample-app-ts"
                slo     = "availability"
              }
            },
            {
              record = "sli:app_availability:ratio_rate1h"
              expr   = "sum(rate(http_server_duration_milliseconds_count{job=\"sample-app-ts\", http_status_code!~\"5..\"}[1h])) / sum(rate(http_server_duration_milliseconds_count{job=\"sample-app-ts\"}[1h]))"
              labels = {
                service = "sample-app-ts"
                slo     = "availability"
              }
            },
          ]
        },
        # ── OTel Collector SLIs ───────────────────────
        {
          name     = "sli:otel_collector:pipeline"
          interval = "30s"
          rules = [
            {
              record = "sli:otel_traces_success:ratio_rate5m"
              expr   = "(sum(rate(otelcol_exporter_sent_spans[5m])) / sum(rate(otelcol_receiver_accepted_spans[5m]))) or vector(1)"
              labels = {
                service = "otel-collector"
                slo     = "trace_pipeline"
              }
            },
            {
              record = "sli:otel_traces_success:ratio_rate1h"
              expr   = "(sum(rate(otelcol_exporter_sent_spans[1h])) / sum(rate(otelcol_receiver_accepted_spans[1h]))) or vector(1)"
              labels = {
                service = "otel-collector"
                slo     = "trace_pipeline"
              }
            },
            {
              record = "sli:otel_metrics_success:ratio_rate5m"
              expr   = "(sum(rate(otelcol_exporter_sent_metric_points[5m])) / sum(rate(otelcol_receiver_accepted_metric_points[5m]))) or vector(1)"
              labels = {
                service = "otel-collector"
                slo     = "metric_pipeline"
              }
            },
            {
              record = "sli:otel_metrics_success:ratio_rate1h"
              expr   = "(sum(rate(otelcol_exporter_sent_metric_points[1h])) / sum(rate(otelcol_receiver_accepted_metric_points[1h]))) or vector(1)"
              labels = {
                service = "otel-collector"
                slo     = "metric_pipeline"
              }
            },
            {
              record = "sli:otel_logs_success:ratio_rate5m"
              expr   = "(sum(rate(otelcol_exporter_sent_log_records[5m])) / sum(rate(otelcol_receiver_accepted_log_records[5m]))) or vector(1)"
              labels = {
                service = "otel-collector"
                slo     = "log_pipeline"
              }
            },
            {
              record = "sli:otel_logs_success:ratio_rate1h"
              expr   = "(sum(rate(otelcol_exporter_sent_log_records[1h])) / sum(rate(otelcol_receiver_accepted_log_records[1h]))) or vector(1)"
              labels = {
                service = "otel-collector"
                slo     = "log_pipeline"
              }
            },
          ]
        },
        # ── Loki SLIs ────────────────────────────────
        {
          name     = "sli:loki:ingestion"
          interval = "30s"
          rules = [
            {
              record = "sli:loki_write_success:ratio_rate5m"
              expr   = "(sum(rate(loki_request_duration_seconds_count{route=~\"loki_api_v1_push|/logproto.Pusher/Push\", status_code!~\"5..\"}[5m])) / sum(rate(loki_request_duration_seconds_count{route=~\"loki_api_v1_push|/logproto.Pusher/Push\"}[5m]))) or vector(1)"
              labels = {
                service = "loki"
                slo     = "ingestion"
              }
            },
            {
              record = "sli:loki_write_success:ratio_rate1h"
              expr   = "(sum(rate(loki_request_duration_seconds_count{route=~\"loki_api_v1_push|/logproto.Pusher/Push\", status_code!~\"5..\"}[1h])) / sum(rate(loki_request_duration_seconds_count{route=~\"loki_api_v1_push|/logproto.Pusher/Push\"}[1h]))) or vector(1)"
              labels = {
                service = "loki"
                slo     = "ingestion"
              }
            },
          ]
        },
        # ── Tempo SLIs ───────────────────────────────
        {
          name     = "sli:tempo:ingestion"
          interval = "30s"
          rules = [
            {
              record = "sli:tempo_write_success:ratio_rate5m"
              expr   = "(sum(rate(tempo_request_duration_seconds_count{route=~\"/tempopb.Pusher/PushBytesV2\", status_code!~\"5..\"}[5m])) / sum(rate(tempo_request_duration_seconds_count{route=~\"/tempopb.Pusher/PushBytesV2\"}[5m]))) or vector(1)"
              labels = {
                service = "tempo"
                slo     = "ingestion"
              }
            },
            {
              record = "sli:tempo_write_success:ratio_rate1h"
              expr   = "(sum(rate(tempo_request_duration_seconds_count{route=~\"/tempopb.Pusher/PushBytesV2\", status_code!~\"5..\"}[1h])) / sum(rate(tempo_request_duration_seconds_count{route=~\"/tempopb.Pusher/PushBytesV2\"}[1h]))) or vector(1)"
              labels = {
                service = "tempo"
                slo     = "ingestion"
              }
            },
          ]
        },
        # ── Error Budget Remaining ───────────────────
        {
          name     = "slo:error_budget"
          interval = "1m"
          rules = [
            {
              record = "slo:error_budget_remaining:ratio"
              expr   = "1 - ((1 - sli:app_availability:ratio_rate1h{service=\"sample-app\"}) / 0.001)"
              labels = {
                service   = "sample-app"
                slo       = "availability"
                objective = "99.9"
              }
            },
            {
              record = "slo:error_budget_remaining:ratio"
              expr   = "1 - ((1 - sli:app_availability:ratio_rate1h{service=\"sample-app-ts\"}) / 0.001)"
              labels = {
                service   = "sample-app-ts"
                slo       = "availability"
                objective = "99.9"
              }
            },
            {
              record = "slo:error_budget_remaining:ratio"
              expr   = "1 - ((1 - sli:otel_traces_success:ratio_rate1h) / 0.001)"
              labels = {
                service   = "otel-collector"
                slo       = "trace_pipeline"
                objective = "99.9"
              }
            },
            {
              record = "slo:error_budget_remaining:ratio"
              expr   = "1 - ((1 - sli:otel_metrics_success:ratio_rate1h) / 0.001)"
              labels = {
                service   = "otel-collector"
                slo       = "metric_pipeline"
                objective = "99.9"
              }
            },
            {
              record = "slo:error_budget_remaining:ratio"
              expr   = "1 - ((1 - sli:otel_logs_success:ratio_rate1h) / 0.005)"
              labels = {
                service   = "otel-collector"
                slo       = "log_pipeline"
                objective = "99.5"
              }
            },
            {
              record = "slo:error_budget_remaining:ratio"
              expr   = "1 - ((1 - sli:loki_write_success:ratio_rate1h) / 0.005)"
              labels = {
                service   = "loki"
                slo       = "ingestion"
                objective = "99.5"
              }
            },
            {
              record = "slo:error_budget_remaining:ratio"
              expr   = "1 - ((1 - sli:tempo_write_success:ratio_rate1h) / 0.005)"
              labels = {
                service   = "tempo"
                slo       = "ingestion"
                objective = "99.5"
              }
            },
          ]
        },
      ]
    }
  }
}

# ──────────────────────────────────────────────
# SLO Alerting Rules (multi-window burn rate)
# ──────────────────────────────────────────────
resource "kubernetes_manifest" "slo_alerting_rules" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "slo-alerting-rules"
      namespace = var.namespace
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
        "prometheus"                   = "kube-prometheus"
        "role"                         = "slo"
      }
    }
    spec = {
      groups = [
        {
          name = "slo:alerts:burn_rate"
          rules = [
            {
              alert = "SLOHighErrorBurnRate"
              expr  = "(sli:app_availability:ratio_rate5m{service=~\"sample-app|sample-app-ts\"} < 0.9856 and sli:app_availability:ratio_rate1h{service=~\"sample-app|sample-app-ts\"} < 0.9856) or (sli:otel_traces_success:ratio_rate5m < 0.9856 and sli:otel_traces_success:ratio_rate1h < 0.9856)"
              "for" = "2m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "{{ $labels.service }}: SLO burn rate is critical"
                description = "{{ $labels.service }} is consuming error budget at >14x the sustainable rate. At this pace the monthly budget will be exhausted in < 2 days."
              }
            },
            {
              alert = "SLOModerateErrorBurnRate"
              expr  = "(sli:app_availability:ratio_rate30m{service=~\"sample-app|sample-app-ts\"} < 0.998 and sli:app_availability:ratio_rate1h{service=~\"sample-app|sample-app-ts\"} < 0.998) or (sli:otel_traces_success:ratio_rate1h < 0.998)"
              "for" = "15m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "{{ $labels.service }}: SLO burn rate is elevated"
                description = "{{ $labels.service }} error rate is elevated. At this pace the monthly error budget will be exhausted within 10 days."
              }
            },
            {
              alert = "SLOErrorBudgetExhausted"
              expr  = "slo:error_budget_remaining:ratio <= 0"
              "for" = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "{{ $labels.service }}: Error budget exhausted for {{ $labels.slo }}"
                description = "{{ $labels.service }} has consumed 100% of its error budget for the {{ $labels.slo }} SLO (target: {{ $labels.objective }}%)."
              }
            },
            {
              alert = "SLOErrorBudgetLow"
              expr  = "slo:error_budget_remaining:ratio > 0 and slo:error_budget_remaining:ratio < 0.2"
              "for" = "15m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "{{ $labels.service }}: Error budget below 20% for {{ $labels.slo }}"
                description = "{{ $labels.service }} has consumed >80% of its error budget for the {{ $labels.slo }} SLO. Remaining: {{ $value | humanizePercentage }}."
              }
            },
          ]
        },
      ]
    }
  }
}
