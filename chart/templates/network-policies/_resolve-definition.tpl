{{- define "bb-common.network-policies.resolve-definition" -}}
  {{- $ctx := index . 0 }}
  {{- $direction := index . 1 }}
  {{- $definitionName := index . 2 }}

  {{- $egressDefinitions := include "bb-common.network-policies.egress.definitions.default" . | fromYaml }}
  {{- $ingressDefinitions := include "bb-common.network-policies.ingress.definitions.default" . | fromYaml }}

  {{- $userEgressDefs := dig "egress" "definitions" dict $ctx.Values.networkPolicies }}
  {{- $userIngressDefs := dig "ingress" "definitions" dict $ctx.Values.networkPolicies }}
  
  {{- range $key, $value := $userEgressDefs }}
    {{- $_ := set $egressDefinitions $key $value }}
  {{- end }}
  
  {{- range $key, $value := $userIngressDefs }}
    {{- $_ := set $ingressDefinitions $key $value }}
  {{- end }}

  {{- $definitions := dict "ingress" $ingressDefinitions "egress" $egressDefinitions }}

  {{- $definition := dig $direction $definitionName false $definitions }}
  {{- if not $definition }}
    {{- fail (printf "NetworkPolicy definition '%s' not found in direction '%s'" $definitionName $direction) -}}
  {{- end }}

  {{- $verb := ternary "to" "from" (eq $direction "egress") }}
  {{- if not (dig $verb false $definition) }}
    {{- fail (printf "NetworkPolicy definition '%s' in direction '%s' does not have required '%s' key" $definitionName $direction $verb) -}}
  {{- end }}

  {{- $definition | toYaml }}
{{- end -}}

