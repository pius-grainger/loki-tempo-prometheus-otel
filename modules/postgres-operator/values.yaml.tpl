# Minimal Zalando Postgres Operator configuration
configGeneral:
  enable_crd_registration: true
  min_instances: -1
  max_instances: -1
  resync_period: 30m
  workers: 4

configKubernetes:
  watched_namespace: "${namespace}"
  pod_service_account_name: "postgres-pod"
  spilo_runasuser: 101
  spilo_runasgroup: 103
  spilo_fsgroup: 103

configDebug:
  debug_logging: false
  enable_database_access: true
