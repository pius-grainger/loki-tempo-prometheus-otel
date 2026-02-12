deploymentMode: SingleBinary

loki:
  auth_enabled: false

  storage:
    type: s3
    bucketNames:
      chunks: ${s3_bucket_name}
      ruler: ${s3_bucket_name}
    s3:
      endpoint: https://s3.${aws_region}.amazonaws.com
      region: ${aws_region}

  schemaConfig:
    configs:
      - from: "2024-01-01"
        store: tsdb
        object_store: s3
        schema: v13
        index:
          prefix: loki_index_
          period: 24h

  commonConfig:
    replication_factor: 1

singleBinary:
  replicas: 1

gateway:
  enabled: true

# Disable scalable mode components
read:
  replicas: 0
write:
  replicas: 0
backend:
  replicas: 0

serviceAccount:
  create: true
  name: ${service_account_name}
  annotations:
    eks.amazonaws.com/role-arn: ${irsa_role_arn}

# Enable ServiceMonitor so Prometheus scrapes Loki metrics
monitoring:
  serviceMonitor:
    enabled: true
    labels: {}
  selfMonitoring:
    enabled: false
    grafanaAgent:
      installOperator: false

# Use real S3, not minio
minio:
  enabled: false
