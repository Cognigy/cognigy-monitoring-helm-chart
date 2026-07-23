# cognigy-dashboards

See [Product Dashboards for Cognigy Monitoring Stack](https://cognigy.atlassian.net/wiki/spaces/Engineering/pages/1430585397/Product+Dashboards+for+Cognigy+Monitoring+Stack) for authoring and deployment guidance.

## ⚠️ These dashboards are published publicly

Everything in this chart — **and in the sibling `cognigy-alerts` chart** — ships as part of
the public monitoring-stack release: panel titles and descriptions, variable/templating
fields, alert-rule expressions, annotations, and even the comments in `values.yaml` and the
rule templates. Assume anything you write here is world-readable.

Before committing, review every comment and description for information that should **not** be
public, for example:

- Internal cluster, tenant, customer, or namespace names (see the `templating` note in the
  wiki — keep `current` empty so cluster names do not leak).
- Operational strategy and rollout state — e.g. "disabled by default, enabled per cluster
  after tuning", "warning-only until validated", which alerts we do/don't page on, capacity
  numbers, or how many instances we run.
- Internal ticket IDs, incident references, runbook internals, and infra-specific remediation
  steps beyond what an operator genuinely needs in the alert.

Keep descriptions **technical and neutral** (what the metric means, how to read the panel,
what a healthy value looks like). Put internal "why we did it this way" rationale in the PR
description or an internal doc, not in the published files.
