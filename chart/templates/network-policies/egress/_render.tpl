{{- define "bb-common.network-policies.egress.render" }}
  {{- $ctx := . }}
  {{- $netpols := list }}

  {{- $egressPolicies := dig "egress" "from" dict $ctx.Values.networkPolicies }}
  {{- if $egressPolicies }}
    {{- $egressPolicies = tpl ($egressPolicies | toYaml) $ctx | fromYaml }}
  {{- end }}

  {{- $generators := dict 
    "k8s" "bb-common.network-policies.egress.generate.from-k8s-shorthand"
    "cidr" "bb-common.network-policies.egress.generate.from-cidr-shorthand"
    "definition" "bb-common.network-policies.egress.generate.from-definition"
    "literal" "bb-common.network-policies.egress.generate.from-spec-literal"
  }}

  {{- range $localKey, $localConfig := $egressPolicies }}
    {{- $localName := $localKey }}

    {{- if eq $localName "*" }}
      {{- $localName = "any-pod" }}
    {{- end }}

    {{- range $remoteType, $generator := $generators }}
      {{- range $remoteKey, $remoteConfig := dig "to" $remoteType dict $localConfig }}
        {{- $isEnabled := or (and (kindIs "map" $remoteConfig) (dig "enabled" true $remoteConfig)) (and (kindIs "bool" $remoteConfig) $remoteConfig) }}

        {{- if not $isEnabled }}
          {{- continue }}
        {{- end }}

        {{- $netpol := include "bb-common.network-policies.new" (list $localKey $localConfig.podSelector "egress") | fromYaml }}

        {{- $name := printf "allow-egress-from-%s" $localName }}
        {{- $name = include "bb-common.network-policies.prepend-release-name" (list $ctx $name) }}
        {{- $labels := include "bb-common.network-policies.default-labels" "egress" | fromYaml }}
        {{- $annotations := dict  "generated.network-policies.bigbang.dev/local-key" $localKey }}

        {{- $args := list $ctx $netpol $remoteKey $remoteConfig $name $labels $annotations }}
        {{- $netpol = include $generator $args | fromYaml }}
        {{- $netpol = merge $netpol (include "bb-common.network-policies.metadata-overrides" (list $localConfig $remoteConfig) | fromYaml) }}
        {{- $netpols = append $netpols $netpol }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if dig "hbonePortInjection" "enabled" true $ctx.Values.networkPolicies }}
    {{- $netpols = include "bb-common.network-policies.inject-hbone-ports" (list $netpols "egress") | fromYamlArray }}
  {{- end }}

  {{- if dig "egress" "defaults" "enabled" true $ctx.Values.networkPolicies }} 
    {{- $netpols = concat $netpols (include "bb-common.network-policies.egress.defaults.render" $ctx | fromYamlArray) }}
  {{- end }}

  {{- range $netpol := $netpols }}
    {{- print "---" | nindent 0 }}
    {{- $netpol | toYaml | nindent 0 }}
  {{- end }}
{{- end }}
