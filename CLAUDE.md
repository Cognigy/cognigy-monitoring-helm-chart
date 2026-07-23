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
