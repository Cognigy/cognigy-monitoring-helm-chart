# cognigy-monitoring-stack — Claude instructions

## Grafana dashboards

Dashboards are JSON sources (`cognigy-monitoring/charts/cognigy-dashboards/dashboards/<type>/`)
converted into generated ConfigMap YAML templates (`templates/dashboards/<type>/`).
Never edit the YAML by hand — edit JSON, then regenerate.

**Updating an existing dashboard:** follow
[`DASHBOARD_UPDATE_GUIDE.md`](cognigy-monitoring/charts/cognigy-dashboards/DASHBOARD_UPDATE_GUIDE.md).

**Adding a NEW dashboard** — the guide above does NOT cover this. Two extra steps it omits,
both easy to miss (and both have been missed before):

1. **Register in `scripts/convert-dashboard/var.yaml`** — add `- name: <file> / dashboard_type: <type>`.
   The converter only processes dashboards listed here; an unlisted JSON is silently never rendered.
2. **Add a `values.yaml` entry** under `products.<type>.dashboards.<name>`
   (`enabled` / `yamlVersion` / `refreshInterval` / `timeFrom`) — the template's helm gates read these.

Then regenerate (`./regenerate-dashboards.sh` from the cognigy-dashboards root) and commit
**all four**: JSON, `var.yaml`, `values.yaml`, and the generated template.

**Scoping note:** `regenerate-dashboards.sh` rewrites *every* template. If unrelated templates
show up changed, that's pre-existing drift (a YAML out of sync with its JSON source) — `git checkout`
those files so the commit only contains your dashboard.

## Public release hygiene

This repo is published to a public GitHub repo (Cognigy/cognigy-monitoring-helm-chart) on
every tag — see `.azuredevops/release-pipeline.yaml` for the current mechanics. As of this
writing it publishes the full working tree with no path filtering (only `.git` and
`CHANGELOG` are dropped), so treat every git-tracked file in this repo as potentially
public, not just the chart under `cognigy-monitoring/`. Git history itself is not carried
over, so internal commit-message conventions don't leak — only file *contents* at tag time
matter. If the pipeline changes to filter what gets published, re-check it before relying
on this assumption.

Because of that, nothing below may appear in any tracked file, **including this one** —
don't use real-looking examples when documenting this rule, only abstract placeholders:

- Internal ticket references — Jira, Azure DevOps, Zendesk ticket keys/numbers — even a
  bare ID with no other detail.
- Customer or tenant identifiers — real cluster names, customer names, or any
  namespace/env name that maps to a specific customer.
- Links to internal systems — Teams, Confluence, internal PagerDuty URLs/service IDs,
  internal runbook hosts.
- Internal staff names.
- Data-derived thresholds explained by their source: a config value tuned from a real
  customer incident/telemetry is fine to keep, but the comment must state the generic
  intent ("tuned for a fast crash-restart cycle"), never the customer data point that
  produced it.

Keep inline comments lean: generic technical rationale only — not the backstory of which
incident or ticket prompted a change.

Put the full context instead in:
- The PR description on the internal Azure DevOps PR, and/or
- A comment on the internal Jira ticket.

Both of those stay private — this constraint is specifically about the public GitHub
mirror, not a general ban on referencing tickets in Cognigy-internal channels.
