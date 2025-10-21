{{- define "bb-common.istio.render" }}
  {{- $ctx := . }}
  {{- $istio := $ctx.Values.istio | default dict }}
  {{- if dig "enabled" false $istio }}
    {{- $resources := list }}

    {{- /* Collect Sidecar object */}}
    {{- $sidecar := include "bb-common.istio.defaults.sidecar" $ctx | fromYaml }}
    {{- if $sidecar }}
      {{- $resources = append $resources $sidecar }}
    {{- end }}

    {{- /* Collect PeerAuthentication object */}}
    {{- $peerAuth := include "bb-common.istio.defaults.peer-auth" $ctx | fromYaml }}
    {{- if $peerAuth }}
      {{- $resources = append $resources $peerAuth }}
    {{- end }}

    {{- /* Collect AuthorizationPolicy objects */}}
    {{- $authzPolicies := $istio.authorizationPolicies | default dict }}
    {{- if dig "enabled" false $authzPolicies }}
      {{- $defaultsEnabled := true }}
      {{- if hasKey $authzPolicies "defaults" }}
        {{- $defaultsEnabled = dig "defaults" "enabled" true $authzPolicies }}
      {{- else }}
        {{- $defaultsEnabled = dig "ingress" "defaults" "enabled" true $ctx.Values.networkPolicies }}
      {{- end }}

      {{- if $defaultsEnabled }}
        {{- $resources = concat $resources (include "bb-common.istio.authorization-policies.defaults.render" $ctx | fromYamlArray) }}
      {{- end }}

      {{- $resources = concat $resources (include "bb-common.istio.authorization-policies.additional" $ctx | fromYamlArray) }}
    {{- end }}

    {{- /* Collect custom ServiceEntry objects */}}
    {{- $customServiceEntries := include "bb-common.istio.custom.service-entries" $ctx | fromYamlArray }}
    {{- if $customServiceEntries }}
      {{- $resources = concat $resources $customServiceEntries }}
    {{- end }}

    {{- /* Collect custom AuthorizationPolicy objects */}}
    {{- $customAuthzPolicies := include "bb-common.istio.custom.authorization-policies" $ctx | fromYamlArray }}
    {{- if $customAuthzPolicies }}
      {{- $resources = concat $resources $customAuthzPolicies }}
    {{- end }}

    {{- range $resource := $resources }}
      {{- print "---" | nindent 0 }}
      {{- $resource | toYaml | nindent 0 }}
    {{- end }}
  {{- end }}
{{- end }}
