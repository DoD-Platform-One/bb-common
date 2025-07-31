{{- define "bb-common.network-policies.egress.generate.from-spec-literal" }}
  {{- $ctx := index . 0 }}
  {{- $netpol := index . 1 }}
  {{- $ruleKey := index . 2 }}
  {{- $ruleValue := index . 3 }}
  {{- $name := index . 4 }}
  {{- $labels := index . 5 }}
  {{- $annotations := index . 6 }}

  {{- if not (regexMatch "^[A-Za-z0-9-]+$" $ruleKey) }}
    {{- fail (printf "Rule key '%s' cannot combine shorthand syntax with a spec value" $ruleKey) }}
  {{- end }}
  {{- $name = printf "%s-to-%s" $name (lower $ruleKey) }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/from-spec-literal" ($ruleValue.spec | toYaml) }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/remote-key" $ruleKey }}

  {{- $metadata := dict "name" $name "labels" $labels "annotations" $annotations "namespace" $ctx.Release.Namespace }}
  {{- $_ := set $netpol "metadata" $metadata }}

  {{- $netpol = merge $netpol (dict "spec" (dict "egress" $ruleValue.spec)) }}
  {{- $netpol | toYaml }}
{{- end }}
