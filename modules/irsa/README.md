# IRSA Module

Creates an IAM Role for Kubernetes Service Accounts (IRSA). Enables pods to assume AWS IAM roles via OIDC federation without static credentials.

## How IRSA Works

```
+------------------+      +-------------------+      +----------------+
| K8s Pod          |      | AWS STS           |      | AWS IAM        |
| (ServiceAccount) | ---> | AssumeRoleWith    | ---> | Role + Policy  |
|                  |      | WebIdentity       |      | (S3, etc.)     |
+--------+---------+      +-------------------+      +-------+--------+
         |                                                     |
         |              +-------------------+                  |
         +----- OIDC -->| EKS OIDC Provider |<-- Trust Policy -+
                        +-------------------+
```

## What It Creates

- **IAM Role** with OIDC trust policy scoped to a specific namespace and service account
- **Inline IAM Policy** attached to the role (provided as JSON)

## Trust Policy

The trust policy ensures only the specified Kubernetes service account in the specified namespace can assume this role:

```
Condition:
  StringEquals:
    <oidc_url>:sub = "system:serviceaccount:<namespace>:<service_account>"
    <oidc_url>:aud = "sts.amazonaws.com"
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `role_name` | string | (required) | Name for the IAM role |
| `oidc_provider_arn` | string | (required) | ARN of the EKS OIDC provider |
| `oidc_provider_url` | string | (required) | OIDC provider URL (without `https://`) |
| `namespace` | string | (required) | Kubernetes namespace |
| `service_account_name` | string | (required) | Kubernetes service account name |
| `policy_json` | string | (required) | JSON IAM policy document |
| `tags` | map(string) | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `role_arn` | ARN of the IAM role (annotate on ServiceAccount) |
| `role_name` | Name of the IAM role |

## Usage

```hcl
module "loki_irsa" {
  source = "../irsa"

  role_name            = "staging-loki-irsa"
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  namespace            = "observability"
  service_account_name = "loki"
  policy_json          = data.aws_iam_policy_document.loki_s3.json
}
```
