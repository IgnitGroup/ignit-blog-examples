# Contributing

## Add an article example

1. Create a branch and a directory at `articles/<published-article-slug>/`.
2. Start its README from [templates/article/README.md](templates/article/README.md).
3. Put runnable code in technology-specific directories such as `terraform/`, `python/` or `docker/`.
4. Keep each independently deployable Terraform example in its own root directory and state. Describe all external prerequisites.
5. Update the catalog in the root README. For a new Terraform root, update the validation matrix and Dependabot configuration.
6. Open a pull request and request review from an Ignit maintainer before merging.

Use lowercase directory names with hyphens. Keep examples readable; introduce shared modules when there is a concrete need across examples. Keep the full blog article in the CMS and link it from the example README.

## Document every runnable example

Include its purpose, architecture, prerequisites, supported/tested versions, configuration, deployment, verification, costs, limitations and cleanup. Explain which resources are created and which must already exist. Separate historical article results from tests performed against the current code, and record test dates when running deployment checks.

Use dummy identifiers and sanitized sample inputs. Preserve applicable third-party license notices.

## Terraform checks

From the repository root:

```bash
terraform fmt -check -recursive
```

From each affected Terraform root:

```bash
terraform init -backend=false
terraform validate
```

This repository ignores `.terraform.lock.hcl` files. `terraform init` generates them locally and selects providers within the constraints in `versions.tf`; fresh clones can select different matching versions. Do not commit `.terraform/`, state, saved plans, real `.tfvars` or credentials.

AWS deployment tests require a suitable sandbox and explicit review of the Terraform plan. They are separate from CI validation. Document exactly what was exercised and clean up the resources afterwards.

## Publishing a code revision

When linking code from an article, use a reviewed commit permalink or release tag for reproducibility. Keep the link from this repository back to the published article. Dependency updates and later corrections go through a new pull request.
