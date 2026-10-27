# Security

## Reporting

Do not put credentials, state files, customer data or exploit details in public issues or pull requests. Report sensitive findings privately to the Ignit maintainers through the contact channel on [ignit.group](https://ignit.group/).

For non-sensitive documentation and configuration mistakes, open an issue or pull request describing the affected example and reproduction steps.

## Example scope

These examples accompany engineering articles. Their READMEs describe deployment defaults, limitations and the scope of verification. Review and adapt them before use in a long-lived environment.

Terraform state can contain database passwords even when variables are marked sensitive. Keep state protected and outside version control. Never attach state or saved plans to a public report.
