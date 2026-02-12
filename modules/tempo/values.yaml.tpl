tempo:
  storage:
    trace:
      backend: s3
      s3:
        bucket: ${s3_bucket_name}
        endpoint: s3.${aws_region}.amazonaws.com
        region: ${aws_region}
        insecure: false
        forcepathstyle: true

  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: "0.0.0.0:4317"
        http:
          endpoint: "0.0.0.0:4318"

  retention: ${trace_retention}

%{ if prometheus_remote_write_url != "" }
  metricsGenerator:
    enabled: true
    remoteWriteUrl: "${prometheus_remote_write_url}"
%{ endif }

serviceAccount:
  create: true
  name: ${service_account_name}
  annotations:
    eks.amazonaws.com/role-arn: ${irsa_role_arn}

# Enable ServiceMonitor so Prometheus scrapes Tempo metrics
serviceMonitor:
  enabled: true
