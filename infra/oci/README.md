# OCI Terraform infrastructure

This directory defines the cloud infrastructure required to run ToggleMaster on Oracle Cloud Infrastructure. The configuration is ready for local review and static validation, but **has not been applied**.

## Challenge mapping

| Phase 2 requirement | Terraform resource |
| --- | --- |
| Kubernetes cluster and worker nodes | OKE cluster and managed node pool |
| Five image repositories | Five private OCIR repositories |
| Three independent PostgreSQL databases | Three OCI Database with PostgreSQL systems |
| Redis cache | One non-sharded OCI Cache cluster |
| Standard message queue | One OCI Queue |
| Analytics NoSQL table | One OCI NoSQL table keyed by `event_id` |
| External ingress network | Public load-balancer subnet and NSG for the later Nginx deployment |
| Secure service access | OKE workload-identity policy scoped to two Kubernetes service accounts |

The Terraform also creates a VCN, an internet gateway, a NAT gateway, a service gateway, public API/load-balancer subnets, private worker/data subnets, route tables, and network security groups.

## Deliberate boundaries

Terraform provisions OCI resources only. It does not yet:

- build or push the five images;
- install Metrics Server or Nginx Ingress Controller;
- apply Kubernetes manifests;
- create the three application databases or execute the imported SQL schemas;
- generate an OCIR image-pull secret;
- deploy any application or infrastructure.

Those are later implementation steps. The application code already supports OCI Queue and OCI NoSQL, but the future Kubernetes manifests must inject the Terraform output values and use the `evaluation-service` and `analytics-service` workload-identity service accounts.

## Architecture decisions

- The OKE API endpoint is public but restricted to `api_allowed_cidrs`; worker and data resources have no public IPs.
- OKE uses the Flannel overlay CNI to keep the initial student deployment small and straightforward.
- The default is an Enhanced OKE cluster because OCI workload identity and node cycling are enhanced-cluster features. A Basic cluster is possible only when `create_workload_identity_policy = false`; the applications would then need a different authentication design, such as instance principals.
- The Nginx load balancer will use the dedicated public subnet. Its Kubernetes service must attach `load_balancer_nsg_id`, exposed by the `network` output.
- PostgreSQL credentials reference an existing OCI Vault secret, so the password does not appear in `.tfvars` or outputs.
- OCI Cache is private and TLS-only. The future application value should use the output `redis.tls_url` (`rediss://`).
- The default one-node Redis cluster is a cost-conscious development setting, not a high-availability topology. OCI recommends at least three nodes for reliability; set `redis_node_count = 3` before a production-style deployment if the budget permits.
- Queue producer and consumer access is separated with `queue-push` and `queue-pull`; analytics receives row-level NoSQL access.
- PostgreSQL, Redis, and OKE sizes are variables because service availability, quotas, and cost differ by tenancy and region.

## Prerequisites for a future plan

1. Terraform 1.6 or newer and OCI CLI installed.
2. An OCI CLI profile with permission to manage networking, OKE, OCIR, PostgreSQL, Cache, Queue, NoSQL, and IAM policies in the chosen compartment.
3. A compartment and a supported OCI region.
4. An OCI Vault secret containing a PostgreSQL-compliant administrator password.
5. Enough tenancy limits for three PostgreSQL systems, one OCI Cache cluster, OKE nodes, and related networking resources.
6. A reviewed cost estimate. Three managed PostgreSQL systems, OCI Cache, and Enhanced OKE can be billable resources.

## Local development validation (safe; no deployment)

These commands do not create cloud resources:

```bash
cd infra/oci
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

The provider is pinned in `versions.tf`, and `.terraform.lock.hcl` is committed for reproducibility.

## Prepare inputs later

Copy the example without committing the resulting file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Confirm current OKE versions and images instead of trusting the example placeholders:

```bash
oci ce cluster-options get \
  --cluster-option-id all \
  --compartment-id <compartment-ocid> \
  --profile <profile>

oci ce node-pool-options get \
  --node-pool-option-id all \
  --compartment-id <compartment-ocid> \
  --node-pool-k8s-version <kubernetes-version> \
  --profile <profile>
```

Set `node_image_id` to an OKE image that matches both the selected Kubernetes version and node shape. Terraform preconditions reject unsupported versions, shapes, and image IDs during planning.

## Remote state before the first apply

Real state can contain sensitive infrastructure metadata. Create a versioned, private OCI Object Storage bucket outside this stack, then:

```bash
cp backend.tf.example backend.tf
terraform init -migrate-state
```

Edit `backend.tf` first. Do not place OCI keys or tokens in it; use the OCI profile or environment authentication. The native OCI backend provides state locking.

## Future deployment workflow (not executed now)

After the prerequisites, input review, and remote backend are complete:

```bash
terraform plan -out=togglemaster.tfplan
terraform show togglemaster.tfplan
terraform apply togglemaster.tfplan
```

Applying can create billable resources. A human must review the saved plan and OCI pricing before the final command.

After a successful future apply, obtain the resource handoff with `terraform output`. The `kubeconfig_command` output is intentionally a command string; Terraform does not modify the operator's kubeconfig.
