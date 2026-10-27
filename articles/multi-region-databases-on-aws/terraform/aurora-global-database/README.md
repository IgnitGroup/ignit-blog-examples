# Aurora PostgreSQL Global Database

This example creates an Aurora PostgreSQL Global Database from an empty AWS
account setup:

- one isolated VPC with two database subnets in Ireland (`eu-west-1`)
- one isolated VPC with two database subnets in Frankfurt (`eu-central-1`)
- a regional KMS key and database security group in each Region
- a Serverless v2 writer cluster in Ireland
- a Serverless v2 reader cluster in Frankfurt
- one Aurora Global Database joining both regional clusters

No VPC peering is required for Aurora Global Database replication. Applications
still need their own routed network path to the database endpoints.

## Prerequisites

- Terraform 1.6 or newer; repository CI uses Terraform 1.15.3.
- AWS credentials for a sandbox account with permissions to create VPC, KMS and RDS resources in both Regions. Select the intended account through your local AWS credential configuration.
- Engine version and instance/capacity availability in both selected Regions, sufficient quotas, and a review of the billable resources.

## Deploy

Run from this example directory. Supply `database_password` at Terraform's sensitive input prompt, or provide `TF_VAR_database_password` through your local secret tooling. Do not save it in committed files. Terraform stores it in state, so protect state and use a secure remote backend for shared or long-lived deployments.

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
```

Review the plan before proceeding. `terraform apply` creates a fresh plan and asks for confirmation; verify its actions again.

The initial deployment can take several minutes. Confirm that the global
cluster and both regional clusters are `Available` before testing reads or a
recovery operation.

The example defaults to Aurora PostgreSQL 16.6. Confirm current Global Database and Serverless v2 support in both selected Regions before applying; override `engine_version` if needed. The regional clusters use the same engine version.

## Verification scope and sizing

This standalone configuration has not been recorded as deployed in AWS. The [article overview](../../README.md#verification-and-differences-from-the-article) distinguishes the earlier article test from these files.

Defaults are 8–16 ACUs for the primary and 0.5–4 ACUs for the secondary. They differ from the article's earlier 0.5–4 ACU test and create billable compute in both Regions. These are example settings, not a sizing recommendation for your workload.

After deployment, verify both regional clusters and instances are `Available` and belong to the same global database. SQL replication, application connectivity and recovery must be tested separately from resource provisioning.

## Headless secondary

Set `create_secondary_instance = false` to create a secondary cluster without a
DB instance. Storage-level replication continues, reducing standby compute
cost, but the secondary cannot serve reads and is not immediately ready for a
switchover or failover. Create capacity and wait for the instance to become
available before promotion. This is a cost-versus-recovery-time choice.

## Recovery

- Use a **switchover** for a planned operation while both Regions are healthy.
  Aurora waits for synchronization and changes the primary Region without
  intentional data loss.
- Use a **failover** only when the primary Region is unavailable. Transactions
  that did not reach the secondary can be lost.

Recovery is a separately reviewed operational action. The outputs in this example expose regional endpoints; plan how clients discover the current writer, refresh connections, and resume traffic after a role change.

A switchover or failover changes the topology managed by this configuration. Before applying Terraform afterwards, reconcile the desired regional roles and state with the actual topology and inspect the complete plan for replacements. The `ignore_changes` entry on `replication_source_identifier` is not a complete failover reconciliation strategy. Do not blindly apply the original topology after recovery.

## Clean up

```bash
terraform destroy
```

Run cleanup from this same directory and review the destroy plan. With the demo defaults, databases are deleted without a final snapshot.

KMS keys enter their seven-day scheduled deletion window after destroy. The demo defaults
skip final snapshots and disable deletion protection. Change both behaviors for
a long-lived environment.
