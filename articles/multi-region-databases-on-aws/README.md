# Multi-region databases on AWS

Code accompanying [Multi-region databases on AWS: deploying Aurora Global Database with Terraform](https://ignit.group/blog/multi-region-databases-on-aws).

Author: Admir Osmanovic. Article published September 9, 2026.

## Examples

| Example | Topology | Start here |
| --- | --- | --- |
| Aurora PostgreSQL Global Database | Aurora Serverless v2 writer and optional secondary reader across two Regions | [README](terraform/aurora-global-database/README.md) |
| RDS MySQL cross-Region read replica | Source DB instance and asynchronous replica across two Regions | [README](terraform/rds-mysql-cross-region-read-replica/README.md) |

Each example creates two new VPCs, four private database subnets (two in different availability zones per Region), route tables, DB subnet groups, security groups, regional KMS keys and its database resources. Existing VPCs are not required. The default Regions are Ireland (`eu-west-1`) and Frankfurt (`eu-central-1`).

The two examples are independent Terraform roots. Run them separately; they do not share state or networking.

## Networking and access

The VPCs contain isolated database subnets without Internet Gateways, NAT Gateways or peering. Database endpoints are private, and inbound client access is empty by default. Adding a security-group rule alone does not create a network path: arrange connectivity from a trusted client separately. Cross-Region database replication is managed by AWS.

## Verification and differences from the article

The published article records an earlier Aurora PostgreSQL 14.20 deployment: 18 resources were added and the global database, regional clusters and instances reached `Available`. SQL replication, application routing, switchover, failover and the headless variation were not exercised. RDS MySQL was an alternative discussed in the article, not a recorded deployment test.

These standalone examples include their own networking and differ from that original test. Aurora currently defaults to PostgreSQL 16.6, primary capacity of 8–16 ACUs and secondary capacity of 0.5–4 ACUs. The article's test used a smaller capacity range. Do not expect the original resource count or assume that the earlier deployment proves these exact files have been deployed.

Static validation does not confirm current engine/class availability, account quotas, SQL replication or recovery behavior. Check availability in both selected Regions and review a complete plan before deploying.

## Local validation record

On October 27, 2026, both examples passed `terraform fmt -check -recursive`, backend-free initialization with the unchanged provider lock files, and `terraform validate`, using Terraform 1.15.3 and AWS provider 6.63.0. Initialization reused the already downloaded provider through a local plugin directory.

Repository YAML parsing, local Markdown link checks and Terraform ignore-rule checks also passed. No AWS plan, deployment, SQL replication or recovery test was run for this import. Terraform validation is performed locally. GitHub Actions only checks that every article directory has a record in the root README Articles table.

## Costs and cleanup

Both examples create billable database and KMS resources in two Regions. Aurora primary compute starts at 8 ACUs with the current defaults. Review current AWS pricing before deployment. Use a sandbox and follow each example's cleanup instructions.

The demo defaults disable deletion protection and skip final database snapshots. Destroy permanently deletes the databases without a final snapshot; KMS keys remain pending deletion for seven days. Adapt retention and protection settings for long-lived use.
