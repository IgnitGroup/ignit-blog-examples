# RDS MySQL cross-Region read replica

This example creates an encrypted RDS MySQL source instance in Ireland
(`eu-west-1`) and an encrypted cross-Region read replica in Frankfurt
(`eu-central-1`). It also creates an isolated VPC, two database subnets, a security group and a regional KMS key in each Region from scratch.

This is not an RDS cluster. The two DB instances are connected by asynchronous
replication, and the Frankfurt instance remains read-only until it is promoted.

## Prerequisites

- Terraform 1.6 or newer; local validation used Terraform 1.15.3.
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

Review the complete plan before proceeding. `terraform apply` creates a fresh plan and asks for confirmation; verify its actions again.

Backups are enabled on the source because RDS requires automated backups before
it can create a read replica. The AWS provider uses the source ARN to create the
replica in the second Region and encrypts it with that Region's KMS key.

## Verification scope

This configuration has not been recorded as deployed in AWS. The RDS MySQL topology was discussed as an alternative in the article; its provisioning, SQL replication and promotion require their own tests. See the [article overview](../../README.md#verification-and-differences-from-the-article).

After deployment, verify the source and replica are `Available` and that the replica references the expected source. Test SQL replication from a client with a routed private network connection. Each DB instance uses a single-AZ configuration; cross-Region replication does not add local Multi-AZ failover.

## Promotion is a separate operation

Creating a read replica does not provide automatic regional failover. During a
planned migration or regional incident, promote the replica explicitly through
your approved recovery workflow. Promotion stops replication and
makes the replica an independent writable DB instance.

Promotion must be separately authorized and followed by reconciliation of the Terraform configuration and state. This example does not initiate promotion or manage application routing.

Wait until the promoted instance is `Available`, then switch application
configuration or DNS to its endpoint. Promotion can lose data that had not yet
replicated, so monitor replica lag and test the complete recovery procedure.

Terraform ignores later changes to `replicate_source_db`. This prevents a
successful manual or automated promotion from causing Terraform to re-create
the replica on the next plan. It also means Terraform does not perform or undo
the recovery operation.

## Clean up

```bash
terraform destroy
```

Run cleanup from this same directory and review the destroy plan. With the demo defaults, databases are deleted without a final snapshot.

KMS keys enter their seven-day scheduled deletion window after destroy. The demo defaults
skip final snapshots and disable deletion protection. Change both behaviors for
a long-lived environment.
