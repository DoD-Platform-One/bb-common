{{- define "bb-common.network-policies.ingress.generate.from-spec-literal" }}
  {{- $ctx := index . 0 }}
  {{- $netpol := index . 1 }}
  {{- $remoteKey := index . 2 }}
  {{- $remoteValue := index . 3 }}
  {{- $name := index . 4 }}
  {{- $labels := index . 5 }}
  {{- $annotations := index . 6 }}

  {{- if not (regexMatch "^[A-Za-z0-9-]+$" $remoteKey) }}
    {{- fail (printf "Rule key '%s' cannot combine shorthand syntax with a spec value" $remoteKey) }}
  {{- end }}
  {{- $name = printf "%s-from-%s" $name (lower $remoteKey) }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/from-spec-literal" ($remoteValue.spec | toYaml) }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/remote-key" $remoteKey }}

  {{- $metadata := dict "name" $name "labels" $labels "annotations" $annotations "namespace" $ctx.Release.Namespace }}
  {{- $_ := set $netpol "metadata" $metadata }}

  {{- $netpol = merge $netpol (dict "spec" (dict "ingress" $remoteValue.spec)) }}
  {{- $netpol | toYaml }}
{{- end }}
