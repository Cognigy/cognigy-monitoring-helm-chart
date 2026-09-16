{{/*
Renders the Alloy River configuration for the Tempo trace-ingest edge
collector.

Every replica runs both roles (see the plan / README for the diagram):
  1. Ingest tier   : receives OTLP, tags it with k8s + cluster identity,
                     then hands it to the loadbalancing exporter, which
                     routes each trace (by trace ID) to the one replica
                     that owns it.
  2. Sampling tier : receives the routed trace on the internal port,
                     tail-samples it, batches it, and exports to Tempo
                     through a disk-backed queue.

This keeps the config identical at any replica count — replicas are owned
by the chart's HPA (`alloy.controller.autoscaling.horizontal`), or by
`alloy.controller.replicas` when autoscaling is disabled, with nothing
else to change either way.
*/}}
{{- define "cognigy-alloy.config" -}}
{{- $clusterName := required "cognigy-alloy.clusterName is required (set it to the Flux cluster name)" .Values.clusterName }}
{{- $clusterAttribute := .Values.clusterAttribute | default "cluster" }}
{{- $tempoEndpoint := required "cognigy-alloy.tempo.endpoint is required (host:port of the regional Tempo OTLP endpoint)" .Values.tempo.endpoint }}
{{- $tenant := .Values.tempo.tenant | default $clusterName }}
{{- $authType := .Values.tempo.auth.type | default "none" }}
{{- if not (has $authType (list "none" "basic" "bearer" "mtls")) }}
{{ fail (printf "cognigy-alloy: tempo.auth.type %q must be one of: none, basic, bearer, mtls" $authType) }}
{{- end }}
{{- if and (or (eq $authType "basic") (eq $authType "bearer")) .Values.tempo.tls.insecure }}
{{ fail (printf "cognigy-alloy: tempo.auth.type %q cannot be combined with tempo.tls.insecure: true — gRPC refuses to send credentials over a plaintext channel (verified: \"grpc: the credentials require transport level security\"), and unlike a startup failure this fails per-component while the pod stays healthy. Use tempo.tls.insecureSkipVerify instead if you need to skip certificate validation against a self-signed endpoint." $authType) }}
{{- end }}
{{- range .Values.routes }}
{{- if eq .name "default" }}
{{ fail (printf "cognigy-alloy: routes[].name %q is reserved for the default route — choose a different name" .name) }}
{{- end }}
{{- if not (regexMatch "^[a-z][a-z0-9_]*$" .name) }}
{{ fail (printf "cognigy-alloy: routes[].name %q must match ^[a-z][a-z0-9_]*$ (used verbatim as a River component label)" .name) }}
{{- end }}
{{- if not .tempo }}
{{ fail (printf "cognigy-alloy: routes[%s].tempo is required" .name) }}
{{- end }}
{{- if not .match }}
{{ fail (printf "cognigy-alloy: routes[%s].match is required (a non-empty OTTL boolean expression)" .name) }}
{{- end }}
{{- end }}
logging {
  level  = "info"
  format = "logfmt"
}

// ---------------------------------------------------------------------
// Ingest tier: OTLP from product services, k8s + cluster enrichment,
// then hand off by trace ID to whichever replica owns that trace.
// ---------------------------------------------------------------------

otelcol.receiver.otlp "ingest" {
  grpc {
    endpoint          = "0.0.0.0:{{ .Values.ports.grpc }}"
    max_recv_msg_size = "{{ .Values.receivers.maxRequestSize }}"
  }
  http {
    endpoint              = "0.0.0.0:{{ .Values.ports.http }}"
    max_request_body_size = "{{ .Values.receivers.maxRequestSize }}"
  }

  output {
    traces = [otelcol.processor.k8sattributes.ingest.input]
  }
}

otelcol.processor.k8sattributes "ingest" {
  extract {
    metadata = [
      "k8s.namespace.name",
      "k8s.deployment.name",
      "k8s.statefulset.name",
      "k8s.daemonset.name",
      "k8s.cronjob.name",
      "k8s.job.name",
      "k8s.node.name",
      "k8s.pod.name",
      "k8s.pod.uid",
      "k8s.pod.start_time",
    ]
  }

  // Must stay on the ingest tier. After the loadbalancing hop below the
  // client is a peer Alloy pod, not the emitting service, so associating
  // by connection has to happen before that hop.
  pod_association {
    source {
      from = "connection"
    }
  }

  output {
    traces = [otelcol.processor.transform.cluster_identity.input]
  }
}

otelcol.processor.transform "cluster_identity" {
  error_mode = "ignore"

  trace_statements {
    context = "resource"
    statements = [
      `set(resource.attributes["{{ $clusterAttribute }}"], "{{ $clusterName }}")`,
    ]
  }

  output {
    traces = [otelcol.exporter.loadbalancing.sampling_tier.input]
  }
}

otelcol.exporter.loadbalancing "sampling_tier" {
  routing_key = "traceID"

  resolver {
    kubernetes {
      service = "{{ .Values.alloyFullname }}-cluster"
      ports   = [{{ .Values.ports.internal }}]
    }
  }

  protocol {
    otlp {
      client {
        // Peer-to-peer hop on the private in-cluster network (port
        // {{ .Values.ports.internal }}, never exposed outside the pod's own
        // Service). The OTLP client defaults to TLS; the internal receiver
        // below only speaks plaintext, so this must be explicit.
        tls {
          insecure = true
        }
      }
    }
  }
}

// ---------------------------------------------------------------------
// Sampling tier: reached only via the peer-to-peer hop above, never
// directly by product services. All spans of a trace land here on the
// same replica — this is what lets each chain below make a per-trace
// decision (tail-sampling included) with the whole trace in view, no
// matter how many chains there are.
// ---------------------------------------------------------------------

otelcol.receiver.otlp "internal" {
  grpc {
    endpoint          = "0.0.0.0:{{ .Values.ports.internal }}"
    max_recv_msg_size = "{{ .Values.receivers.maxRequestSize }}"
  }

  output {
    {{- if .Values.routes }}
    // Fan out: every configured chain below gets its OWN copy of every
    // trace and independently decides what to keep via its own filter.
    traces = [
      otelcol.processor.filter.default.input,
      {{- range .Values.routes }}
      otelcol.processor.filter.{{ .name }}.input,
      {{- end }}
    ]
    {{- else }}
    traces = [otelcol.processor.tail_sampling.default.input]
    {{- end }}
  }
}

{{- if .Values.routes }}

// Default chain: excludes anything claimed by another route below, so a
// trace goes to exactly one destination rather than the default AND a
// route. Everything else continues into tail-sampling exactly as before.
otelcol.processor.filter "default" {
  error_mode = "ignore"

  trace_conditions {
    context = "span"
    conditions = [
      {{- range .Values.routes }}
      `{{ .match }}`,
      {{- end }}
    ]
  }

  output {
    traces = [otelcol.processor.tail_sampling.default.input]
  }
}
{{- end }}

otelcol.processor.tail_sampling "default" {
  decision_wait               = "{{ .Values.sampling.decisionWait }}"
  num_traces                  = {{ .Values.sampling.numTraces }}
  expected_new_traces_per_sec = {{ .Values.sampling.expectedNewTracesPerSec }}
  sample_on_first_match       = {{ .Values.sampling.sampleOnFirstMatch }}

  {{- if .Values.sampling.dropUrlPaths }}
  policy {
    name = "drop-health-checks"
    type = "drop"

    drop {
      drop_sub_policy {
        name = "drop-health-checks-match"
        type = "string_attribute"

        string_attribute {
          key                    = "url.path"
          values                 = [{{ range .Values.sampling.dropUrlPaths }}"{{ . }}", {{ end }}]
          enabled_regex_matching = true
        }
      }
    }
  }
  {{- end }}

  {{- range .Values.sampling.policies }}
  policy {
    name = "{{ .name }}"
    type = "{{ .type }}"

    {{- if eq .type "status_code" }}
    status_code {
      status_codes = [{{ range .statusCodes }}"{{ . }}", {{ end }}]
    }
    {{- else if eq .type "latency" }}
    latency {
      threshold_ms = {{ .thresholdMs }}
    }
    {{- else if eq .type "probabilistic" }}
    probabilistic {
      sampling_percentage = {{ .percentage }}
    }
    {{- else }}
    {{ fail (printf "cognigy-alloy: unsupported sampling.policies[].type %q for policy %q — add it to templates/_config.tpl first" .type .name) }}
    {{- end }}
  }
  {{- end }}

  output {
    traces = [otelcol.processor.batch.default.input]
  }
}

otelcol.processor.batch "default" {
  send_batch_size     = {{ .Values.batch.sendBatchSize }}
  send_batch_max_size = {{ .Values.batch.sendBatchMaxSize }}
  timeout             = "{{ .Values.batch.timeout }}"

  output {
    traces = [otelcol.exporter.otlp.tempo.input]
  }
}

// Disk-backed queue: spans survive a Tempo outage instead of being
// dropped from memory while the pod stays up. NOT durable across a pod
// restart/reschedule/eviction — the volume is an emptyDir
// (alloy.controller.volumes.extra), not a PVC. Directory must be a
// subpath of that volume's mount (alloy.alloy.mounts.extra).
otelcol.storage.file "queue" {
  directory = "{{ .Values.queue.directory }}"
  fsync     = {{ .Values.queue.fsync }}
}

// Real request authentication, separate from the X-Scope-OrgID tenant
// header below (client.headers vs client.auth are independent — the
// tenant header is always sent regardless of auth.type). Credentials are
// never in values.yaml: these read fixed env var names that must be wired
// via alloy.alloy.extraEnv in the umbrella values — see the README.
{{- if eq $authType "basic" }}
otelcol.auth.basic "tempo" {
  username = sys.env("TEMPO_AUTH_USERNAME")
  password = sys.env("TEMPO_AUTH_PASSWORD")
}
{{- else if eq $authType "bearer" }}
otelcol.auth.bearer "tempo" {
  token = sys.env("TEMPO_AUTH_TOKEN")
}
{{- end }}

otelcol.exporter.otlp "tempo" {
  client {
    endpoint = "{{ $tempoEndpoint }}"
    headers = {
      "X-Scope-OrgID" = "{{ $tenant }}",
    }
    {{- if eq $authType "basic" }}
    auth = otelcol.auth.basic.tempo.handler
    {{- else if eq $authType "bearer" }}
    auth = otelcol.auth.bearer.tempo.handler
    {{- end }}

    tls {
      insecure             = {{ .Values.tempo.tls.insecure }}
      insecure_skip_verify = {{ .Values.tempo.tls.insecureSkipVerify }}
      {{- if .Values.tempo.tls.caFile }}
      ca_file              = "{{ .Values.tempo.tls.caFile }}"
      {{- end }}
      {{- if eq $authType "mtls" }}
      // Client cert/key for mTLS — mounted from a Secret volume via
      // alloy.controller.volumes.extra + alloy.alloy.mounts.extra at this
      // exact path. Server-CA verification is the separate tempo.tls.caFile
      // knob above, unaffected by this.
      cert_file            = "/etc/alloy-secrets/tempo-mtls/tls.crt"
      key_file             = "/etc/alloy-secrets/tempo-mtls/tls.key"
      {{- end }}
    }
  }

  sending_queue {
    enabled       = true
    num_consumers = {{ .Values.queue.numConsumers }}
    queue_size    = {{ .Values.queue.queueSize }}
    storage       = otelcol.storage.file.queue.handler
  }
}

{{- if .Values.routes }}

// ---------------------------------------------------------------------
// Extra routes: each one only ever sees the traces the default chain's
// filter above excluded. Simplified relative to the default — everything
// that passes the filter is kept as-is (no tail-sampling) and the
// sending_queue is in-memory only (no otelcol.storage.file reference).
// ---------------------------------------------------------------------
{{- end }}

{{- range .Values.routes }}
{{- $routeBatch := .batch | default dict }}
{{- $routeTls := (.tempo.tls | default dict) }}
otelcol.processor.filter "{{ .name }}" {
  error_mode = "ignore"

  trace_conditions {
    context    = "span"
    conditions = [`not ({{ .match }})`]
  }

  output {
    traces = [otelcol.processor.batch.{{ .name }}.input]
  }
}

otelcol.processor.batch "{{ .name }}" {
  send_batch_size     = {{ $routeBatch.sendBatchSize | default $.Values.batch.sendBatchSize }}
  send_batch_max_size = {{ $routeBatch.sendBatchMaxSize | default $.Values.batch.sendBatchMaxSize }}
  timeout             = "{{ $routeBatch.timeout | default $.Values.batch.timeout }}"

  output {
    traces = [otelcol.exporter.otlp.{{ .name }}.input]
  }
}

otelcol.exporter.otlp "{{ .name }}" {
  client {
    endpoint = "{{ required (printf "cognigy-alloy: routes[%s].tempo.endpoint is required" .name) .tempo.endpoint }}"
    headers = {
      "X-Scope-OrgID" = "{{ .tempo.tenant | default $clusterName }}",
    }

    tls {
      insecure             = {{ $routeTls.insecure | default false }}
      insecure_skip_verify = {{ $routeTls.insecureSkipVerify | default false }}
      {{- if $routeTls.caFile }}
      ca_file              = "{{ $routeTls.caFile }}"
      {{- end }}
    }
  }

  // In-memory queue only — no `storage =`, unlike the default route.
  sending_queue {
    enabled = true
  }
}
{{- end }}
{{- end }}
