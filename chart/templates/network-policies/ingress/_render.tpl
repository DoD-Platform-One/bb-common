{{- define "bb-common.network-policies.ingress.render" }}
  {{- $ctx := . }}
  {{- $netpols := list }}
  {{- $authzpols := list }}

  {{- $ingressPolicies := dig "ingress" "to" dict .Values.networkPolicies }}
  {{- if $ingressPolicies }}
    {{- $ingressPolicies = tpl ($ingressPolicies | toYaml) $ | fromYaml }}
  {{- end }}

  {{- $generators := dict
    "k8s" "bb-common.network-policies.ingress.generate.from-k8s-shorthand"
    "cidr" "bb-common.network-policies.ingress.generate.from-cidr-shorthand"
    "definition" "bb-common.network-policies.ingress.generate.from-definition"
    "literal" "bb-common.network-policies.ingress.generate.from-spec-literal"
  }}

  {{- range $localKey, $localConfig := $ingressPolicies }}
    {{- $localParsed := include "bb-common.network-policies.ingress.parse.local-key" $localKey | fromYaml }}

    {{- range $remoteType, $generator := $generators }}
      {{- range $remoteKey, $remoteConfig := dig "from" $remoteType dict $localConfig }}
        {{- $isEnabled := or (and (kindIs "map" $remoteConfig) (dig "enabled" true $remoteConfig)) (and (kindIs "bool" $remoteConfig) $remoteConfig) }}

        {{- if not $isEnabled }}
          {{- continue }}
        {{- end }}

        {{- $netpol := include "bb-common.network-policies.new" (list $localParsed.name $localConfig.podSelector "ingress") | fromYaml }}
        {{- $name := printf "allow-ingress-to-%s" $localParsed.name }}
        {{- $name = include "bb-common.network-policies.prepend-release-name" (list $ctx $name) }}
        {{- $labels := include "bb-common.network-policies.default-labels" "ingress" | fromYaml }}
        {{- $annotations := dict  "generated.network-policies.bigbang.dev/local-key" $localKey }}

        {{- if $localConfig.podSelector }}
          {{- $_ := set $annotations "generated.network-policies.bigbang.dev/with-local-selector-override" ($localConfig.podSelector | toYaml) }}
        {{- end }}

        {{- if and $localParsed.protocol (not (eq $localParsed.protocol "TCP")) }}
          {{- $name = printf "%s-%s" $name (lower $localParsed.protocol) }}
        {{- end }}

        {{- $args := list $ctx $netpol $remoteKey $remoteConfig $name $labels $annotations $localParsed }}
        {{- $netpol = include $generator $args | fromYaml }}
        {{- $netpol = merge $netpol (include "bb-common.network-policies.metadata-overrides" (list $localConfig $remoteConfig) | fromYaml) }}
        {{- $netpols = append $netpols $netpol }}

        {{- if and (hasKey $ctx.Values "istio") (dig "authorizationPolicies" "generateFromNetpol" false $ctx.Values.istio) }}
          {{- if eq $remoteType "k8s" }}
            {{- $authzPolicy := include "bb-common.istio.authorization-policies.generate.from-k8s-network-policy" $args | fromYaml }}
            {{- $authzPolicy := merge $authzPolicy (include "bb-common.network-policies.metadata-overrides" (list $localConfig $remoteConfig) | fromYaml) }}
            {{- $authzpols = append $authzpols $authzPolicy }}
          {{- else if eq $remoteType "cidr" }}
            {{- $authzPolicy := include "bb-common.istio.authorization-policies.generate.from-cidr-network-policy" $args | fromYaml }}
            {{- $authzPolicy := merge $authzPolicy (include "bb-common.network-policies.metadata-overrides" (list $localConfig $remoteConfig) | fromYaml) }}
            {{- $authzpols = append $authzpols $authzPolicy }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if dig "ingress" "defaults" "enabled" true $ctx.Values.networkPolicies }} 
    {{- $netpols = concat $netpols (include "bb-common.network-policies.ingress.defaults.render" $ctx | fromYamlArray) }}
  {{- end }}

  {{- range $netpol := $netpols }}
    {{- print "---" | nindent 0 }}
    {{- $netpol | toYaml | nindent 0 }}
  {{- end }}
  
  {{- range $authzpol := $authzpols }}
    {{- print "---" | nindent 0 }}
    {{- $authzpol | toYaml | nindent 0 }}
  {{- end }}
{{- end }}
