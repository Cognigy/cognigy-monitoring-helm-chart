# Grafana dashboard review

Run the **grafana-dashboard** skill before you open or approve this PR. Full process: [Creating and Reviewing Grafana Dashboards with the grafana-dashboard Skill](https://cognigy.atlassian.net/wiki/spaces/Engineering/pages/2692677827). What counts as compliant is defined by [Product Dashboards for Cognigy Monitoring Stack](https://cognigy.atlassian.net/wiki/spaces/Engineering/pages/1430585397), which the skill fetches live on every review, so its checks are never stale.

- **Author (Mode A, before you request review):** start Claude Code from this repo root and ask: `Check my dashboard changes against the Product Dashboards guideline.` It verifies the `datasource`/`cluster` variable order, `$datasource` on every panel, a `cluster` filter on every query, the templated timezone and `uid`, and the `var.yaml` / `values.yaml` entries — including `yamlVersion: true`, without which the dashboard merges and then silently never appears in Grafana.
- **Reviewer (Mode B, PR link):** with the Azure DevOps MCP connected, hand the skill this PR: `Review this Grafana dashboard PR: <paste this PR URL>` — add the Jira ticket if there is one. It derives its checks from the live guideline, verifies each one against the PR branch, and posts a single consolidated review back to this PR after showing it to you first.

Mode B fetches the PR branch into a throwaway `git worktree`, so run it from a local clone of this repo — your own checkout is left untouched.

Needs a Confluence MCP connected to the **Cognigy** tenant with Engineering-space access. First-time install: `/plugin marketplace add Cognigy/agent-plugins` then `/plugin install grafana@Cognigy-skills`.

---

# Security

Please assess your changes and describe the potential impact of your change regarding the following checklist:

- [ ] A new ingress has been added which exposes functionality to the outside world
- [ ] A new service has been added to expose functionality inside of the cluster - is the service of type NodePort?
- [ ] Annotations for services or ingress objects have been changed
- [ ] No security relevant change
