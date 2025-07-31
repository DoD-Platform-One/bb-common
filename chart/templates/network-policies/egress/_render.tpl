{{- define "bb-common.network-policies.egress.render" }}
  {{- $ctx := . }}
  {{- $netpols := list }}

  {{- $egressPolicies := dig "egress" "from" dict $ctx.Values.networkPolicies }}
  {{- if $egressPolicies }}
    {{- $egressPolicies = tpl ($egressPolicies | toYaml) $ctx | fromYaml }}
  {{- end }}

  {{- range $localKey, $localConfig := $egressPolicies }}
    {{- $local := $localKey }}

    {{- /* Process k8s rules */}}
    {{- range $remoteKey, $remoteValue := dig "to" "k8s" dict $localConfig }}
      {{- $isEnabled := or (and (kindIs "map" $remoteValue) (dig "enabled" false $remoteValue)) (and (kindIs "bool" $remoteValue) $remoteValue) }}
      {{- if not $isEnabled }}
        {{- continue }}
      {{- end }}

      {{- $netpol := include "bb-common.network-policies.new" (list $local $localConfig.podSelector "egress") | fromYaml }}
      {{- if eq $local "*" }}
        {{- $local = "any-pod" }}
      {{- end }}
      {{- $name := printf "allow-egress-from-%s" $local }}
      {{- $name = include "bb-common.network-policies.prepend-release-name" (list $ctx $name) }}
      {{- $labels := include "bb-common.network-policies.default-labels" "egress" | fromYaml }}
      {{- $annotations := dict  "generated.network-policies.bigbang.dev/local-key" $localKey }}

      {{- $args := list $ctx $netpol $remoteKey $remoteValue $name $labels $annotations $local }}
      {{- $netpol = include "bb-common.network-policies.egress.generate.from-k8s-shorthand" $args | fromYaml }}
      {{- $netpols = append $netpols $netpol }}
    {{- end }}

    {{- /* Process cidr rules */}}
    {{- range $remoteKey, $remoteValue := dig "to" "cidr" dict $localConfig }}
      {{- $isEnabled := or (and (kindIs "map" $remoteValue) (dig "enabled" false $remoteValue)) (and (kindIs "bool" $remoteValue) $remoteValue) }}
      {{- if not $isEnabled }}
        {{- continue }}
      {{- end }}

      {{- $netpol := include "bb-common.network-policies.new" (list $local $localConfig.podSelector "egress") | fromYaml }}
      {{- if eq $local "*" }}
        {{- $local = "any-pod" }}
      {{- end }}
      {{- $name := printf "allow-egress-from-%s" $local }}
      {{- $name = include "bb-common.network-policies.prepend-release-name" (list $ctx $name) }}
      {{- $labels := include "bb-common.network-policies.default-labels" "egress" | fromYaml }}
      {{- $annotations := dict  "generated.network-policies.bigbang.dev/local-key" $localKey }}

      {{- $args := list $ctx $netpol $remoteKey $remoteValue $name $labels $annotations $local }}
      {{- $netpol = include "bb-common.network-policies.egress.generate.from-cidr-shorthand" $args | fromYaml }}
      {{- $netpols = append $netpols $netpol }}
    {{- end }}

    {{- /* Process definition rules */}}
    {{- range $remoteKey, $remoteValue := dig "to" "definition" dict $localConfig }}
      {{- $isEnabled := or (and (kindIs "map" $remoteValue) (dig "enabled" false $remoteValue)) (and (kindIs "bool" $remoteValue) $remoteValue) }}
      {{- if not $isEnabled }}
        {{- continue }}
      {{- end }}

      {{- $netpol := include "bb-common.network-policies.new" (list $local $localConfig.podSelector "egress") | fromYaml }}
      {{- if eq $local "*" }}
        {{- $local = "any-pod" }}
      {{- end }}
      {{- $name := printf "allow-egress-from-%s" $local }}
      {{- $name = include "bb-common.network-policies.prepend-release-name" (list $ctx $name) }}
      {{- $labels := include "bb-common.network-policies.default-labels" "egress" | fromYaml }}
      {{- $annotations := dict  "generated.network-policies.bigbang.dev/local-key" $localKey }}

      {{- $args := list $ctx $netpol $remoteKey $remoteValue $name $labels $annotations $local }}
      {{- $netpol = include "bb-common.network-policies.egress.generate.from-definition" $args | fromYaml }}
      {{- $netpols = append $netpols $netpol }}
    {{- end }}

    {{- /* Process literal rules */}}
    {{- range $remoteKey, $remoteValue := dig "to" "literal" dict $localConfig }}
      {{- $isEnabled := dig "enabled" false $remoteValue }}
      {{- if not $isEnabled }}
        {{- continue }}
      {{- end }}

      {{- $netpol := include "bb-common.network-policies.new" (list $local $localConfig.podSelector "egress") | fromYaml }}
      {{- if eq $local "*" }}
        {{- $local = "any-pod" }}
      {{- end }}
      {{- $name := printf "allow-egress-from-%s" $local }}
      {{- $name = include "bb-common.network-policies.prepend-release-name" (list $ctx $name) }}
      {{- $labels := include "bb-common.network-policies.default-labels" "egress" | fromYaml }}
      {{- $annotations := dict  "generated.network-policies.bigbang.dev/local-key" $localKey }}

      {{- $args := list $ctx $netpol $remoteKey $remoteValue $name $labels $annotations $local }}
      {{- $netpol = include "bb-common.network-policies.egress.generate.from-spec-literal" $args | fromYaml }}
      {{- $netpols = append $netpols $netpol }}
    {{- end }}
  {{- end }}

  {{- if dig "egress" "defaults" "enabled" true $ctx.Values.networkPolicies }} 
    {{- $netpols = concat $netpols (include "bb-common.network-policies.egress.defaults.render" $ctx | fromYamlArray) }}
  {{- end }}

  {{- range $netpol := $netpols }}
    {{- print "---" | nindent 0 }}
    {{- $netpol | toYaml | nindent 0 }}
  {{- end }}
{{- end }}
