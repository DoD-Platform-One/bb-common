{{- define "bb-common.istio.authorization-policies.render" }}
  {{- $ctx := . }}
  {{- $istio := $ctx.Values.istio | default dict }}
  {{- $authzPolicies := $istio.authorizationPolicies | default dict }}
  {{- if dig "enabled" true $authzPolicies }}
    {{- $authzpols := list }}

    {{- $defaultsEnabled := true }}
    {{- if hasKey $authzPolicies "defaults" }}
      {{- $defaultsEnabled = dig "defaults" "enabled" true $authzPolicies }}
    {{- else }}
      {{- $defaultsEnabled = dig "ingress" "defaults" "enabled" true $ctx.Values.networkPolicies }}
    {{- end }}

    {{- if $defaultsEnabled }}
      {{- $authzpols = concat $authzpols (include "bb-common.istio.authorization-policies.defaults.render" $ctx | fromYamlArray) }}
    {{- end }}

    {{- $authzpols = concat $authzpols (include "bb-common.istio.authorization-policies.additional" $ctx | fromYamlArray) }}
    {{- $authzpols = include "bb-common.utils.dedupe" $authzpols | fromYamlArray }}

    {{- range $authzpol := $authzpols }}
      {{- print "---" | nindent 0 }}
      {{- $authzpol | toYaml | nindent 0 }}
    {{- end }}
  {{- end }}
{{- end }}
