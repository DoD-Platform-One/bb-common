{{- define "bb-common.network-policies.egress.defaults.render" }}
  {{- $ctx := . }}
  {{- $netpols := list }}

  {{- if dig "egress" "defaults" "denyAll" "enabled" true $ctx.Values.networkPolicies }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.egress.defaults.deny-all" $ctx | fromYaml) }}
  {{- end }}
  {{- if dig "egress" "defaults" "allowInNamespace" "enabled" true $ctx.Values.networkPolicies }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.egress.defaults.allow-all-in-ns" $ctx | fromYaml) }}
  {{- end }}
  {{- if dig "egress" "defaults" "allowKubeDns" "enabled" true $ctx.Values.networkPolicies }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.egress.defaults.allow-kube-dns" $ctx | fromYaml) }}
  {{- end }}
  {{- if dig "egress" "defaults" "allowIstiod" "enabled" true $ctx.Values.networkPolicies }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.egress.defaults.allow-istiod" $ctx | fromYaml) }}
  {{- end }}

  {{- $netpols | toYaml }}
{{- end }}
