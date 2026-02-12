# EKS Module

Creates a fully functional EKS cluster with networking, IAM, and storage driver.

## Architecture

```
                    +---------------------------+
                    |          VPC              |
                    |  +--------+ +--------+   |
                    |  | Public | | Public |   |
                    |  | Sub-AZ1| | Sub-AZ2|   |
                    |  +---+----+ +---+----+   |
                    |      |          |        |
                    |  +---v----------v---+    |
                    |  |  Internet GW     |    |
                    |  +------------------+    |
                    |      |                   |
                    |  +---v----+              |
                    |  | NAT GW |              |
                    |  +---+----+              |
                    |      |                   |
                    |  +---v-----+ +--------+  |
                    |  | Private | | Private|  |
                    |  | Sub-AZ1 | | Sub-AZ2|  |
                    |  +----+----+ +---+----+  |
                    |       |          |       |
                    +-------|----------|-------+
                            |          |
                    +-------v----------v------+
                    |     EKS Cluster          |
                    |  +-------------------+   |
                    |  | Managed Node Group |   |
                    |  | (SPOT instances)   |   |
                    |  +-------------------+   |
                    |  +-------------------+   |
                    |  | EBS CSI Driver    |   |
                    |  | (addon + IRSA)    |   |
                    |  +-------------------+   |
                    |  +-------------------+   |
                    |  | OIDC Provider     |   |
                    |  | (for IRSA)        |   |
                    |  +-------------------+   |
                    +--------------------------+
```

## What It Creates

- **VPC** with 2 public + 2 private subnets across 2 AZs
- **Internet Gateway** + **NAT Gateway** (single, cost-effective)
- **Route tables** for public (IGW) and private (NAT) subnets
- **EKS Cluster** with public + private API endpoint
- **OIDC Provider** for IAM Roles for Service Accounts (IRSA)
- **Managed Node Group** with configurable instance types and spot support
- **EBS CSI Driver** addon with IRSA (required for PVC provisioning)

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_name` | string | (required) | Name of the EKS cluster |
| `cluster_version` | string | `"1.32"` | Kubernetes version |
| `environment` | string | (required) | Environment name (staging, production) |
| `aws_region` | string | (required) | AWS region |
| `vpc_cidr` | string | `"10.0.0.0/16"` | CIDR block for the VPC |
| `node_instance_types` | list(string) | `["t3.xlarge"]` | EC2 instance types for the node group |
| `node_desired_count` | number | `1` | Desired number of nodes |
| `node_min_count` | number | `1` | Minimum number of nodes |
| `node_max_count` | number | `2` | Maximum number of nodes |
| `node_disk_size` | number | `50` | Disk size in GB per node |
| `capacity_type` | string | `"ON_DEMAND"` | `ON_DEMAND` or `SPOT` |
| `tags` | map(string) | `{}` | Additional tags |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | EKS API endpoint |
| `cluster_certificate_authority` | Base64 CA certificate |
| `oidc_provider_arn` | OIDC provider ARN (for IRSA modules) |
| `oidc_provider_url` | OIDC provider URL (without `https://`) |
| `vpc_id` | VPC ID |
| `private_subnet_ids` | Private subnet IDs |
| `public_subnet_ids` | Public subnet IDs |

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name        = "staging-eks-cluster"
  cluster_version     = "1.32"
  environment         = "staging"
  aws_region          = "eu-west-2"
  node_instance_types = ["t3.xlarge", "t3a.xlarge", "m5.xlarge"]
  node_desired_count  = 2
  capacity_type       = "SPOT"
}
```
