mode: ${mode}

image:
  repository: otel/opentelemetry-collector-contrib

ports:
  otlp:
    enabled: true
    containerPort: 4317
    servicePort: 4317
    protocol: TCP
  otlp-http:
    enabled: true
    containerPort: 4318
    servicePort: 4318
    protocol: TCP
  metrics:
    enabled: true
    containerPort: 8888
    servicePort: 8888
    protocol: TCP

# Expose internal OTel Collector metrics to Prometheus
serviceMonitor:
  enabled: true
  metricsEndpoints:
    - port: metrics

config:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: "0.0.0.0:4317"
        http:
          endpoint: "0.0.0.0:4318"

  processors:
    batch:
      send_batch_size: 1024
      timeout: 5s
    memory_limiter:
      check_interval: 5s
      limit_mib: 512
      spike_limit_mib: 128
%{ if cluster_name != "" }
    resource:
      attributes:
        - key: k8s.cluster.name
          value: "${cluster_name}"
          action: upsert
%{ endif }

  exporters:
    otlp/tempo:
      endpoint: "${tempo_otlp_grpc_endpoint}"
      tls:
        insecure: true

    prometheusremotewrite:
      endpoint: "${prometheus_remote_write_url}"
      tls:
        insecure: true

    loki:
      endpoint: "${loki_push_url}"

    debug:
      verbosity: basic

  extensions:
    health_check:
      endpoint: "0.0.0.0:13133"

  service:
    extensions: [health_check]
    pipelines:
      traces:
        receivers: [otlp]
        processors: [memory_limiter, batch]
        exporters: [otlp/tempo]
      metrics:
        receivers: [otlp]
        processors: [memory_limiter, batch]
        exporters: [prometheusremotewrite]
      logs:
        receivers: [otlp]
        processors: [memory_limiter, batch]
        exporters: [loki]
