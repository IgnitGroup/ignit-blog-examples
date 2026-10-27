# ignit-blog-examples

Runnable code, infrastructure examples, and demos accompanying Ignit engineering blog posts.

## Articles

| Article | Code | Technologies | Verification |
| --- | --- | --- | --- |
| [Multi-region databases on AWS](https://ignit.group/blog/multi-region-databases-on-aws) | [Code and instructions](articles/multi-region-databases-on-aws/) | Terraform, AWS, Aurora PostgreSQL, RDS MySQL | Local format/validation checks passed; current examples require AWS deployment tests. |

## Getting started

1. Choose an article from the catalog.
2. Open its README and select an example.
3. Review its prerequisites, costs and cleanup instructions before deploying.
4. Run commands from the selected example directory.

Each Terraform example is an independent root module with its own state. Provider lock files are generated locally and ignored by Git. Examples do not depend on internal Ignit infrastructure or other article folders. There is no repository-wide Terraform apply.

## Repository layout

```text
articles/
  <article-slug>/
    README.md
    terraform/
      <example-name>/
        README.md
        *.tf
        terraform.tfvars.example
```

Use the published article slug for its directory. Other technologies can have sibling directories such as `python/` or `docker/` when an article needs them.

## Validation

GitHub Actions checks Terraform formatting, initializes providers without a backend, and validates both database examples. CI does not obtain AWS credentials, create infrastructure, or test replication and recovery. The workflow pins Terraform and GitHub Actions dependencies; Dependabot proposes dependency updates for review.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and the [article template](templates/article/README.md). Add or update examples through a pull request.

## Security

See [SECURITY.md](SECURITY.md) for reporting guidance. Never commit credentials, Terraform state, saved plans or private configuration.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
