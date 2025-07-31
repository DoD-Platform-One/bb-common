{{- define "bb-common.network-policies.ingress.defaults.render" }}
  {{- $ctx := . }}
  {{- $netpols := list }}

  {{- if dig "ingress" "defaults" "denyAll" "enabled" true $ctx.Values.networkPolicies }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.ingress.defaults.deny-all" $ctx | fromYaml) }}
  {{- end }}
  {{- if dig "ingress" "defaults" "allowInNamespace" "enabled" true $ctx.Values.networkPolicies }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.ingress.defaults.allow-all-in-ns" $ctx | fromYaml) }}
  {{- end }}

  {{- $netpols | toYaml }}
{{- end }}
