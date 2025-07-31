{{- define "bb-common.network-policies.render" }}
  {{- $ctx := . }}
  {{- if $ctx.Values.networkPolicies.enabled }}
    {{- include "bb-common.network-policies.egress.render" $ctx }}
    {{- include "bb-common.network-policies.ingress.render" $ctx }}
    {{- include "bb-common.network-policies.additional" $ctx }}
  {{- end }}
{{- end }}
