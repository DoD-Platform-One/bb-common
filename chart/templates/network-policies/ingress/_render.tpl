{{- define "bb-common.network-policies.ingress.render" }}
  {{- $ctx := . }}
  {{- $netpols := list }}
  {{- $authzpols := list }}

  {{- $ingressPolicies := dig "ingress" "to" dict .Values.networkPolicies }}
  {{- if $ingressPolicies }}
    {{- $ingressPolicies = tpl ($ingressPolicies | toYaml) $ | fromYaml }}
  {{- end }}

  {{- range $localKey, $localConfig := $ingressPolicies }}
    {{- $local := include "bb-common.network-policies.ingress.parse.local-key" $localKey | fromYaml }}

    {{- /* Process k8s rules */}}
    {{- range $remoteKey, $remoteConfig := dig "from" "k8s" dict $localConfig }}
      {{- $isEnabled := or (and (kindIs "map" $remoteConfig) (dig "enabled" false $remoteConfig)) (and (kindIs "bool" $remoteConfig) $remoteConfig) }}
      {{- if not $isEnabled }}
        {{- continue }}
      {{- end }}

      {{- $netpol := include "bb-common.network-policies.new" (list $local.name $localConfig.podSelector "ingress") | fromYaml }}
      {{- $name := printf "allow-ingress-to-%s" $local.name }}
      {{- $name = include "bb-common.network-policies.prepend-release-name" (list $ctx $name) }}
      {{- $labels := include "bb-common.network-policies.default-labels" "ingress" | fromYaml }}
      {{- $annotations := dict  "generated.network-policies.bigbang.dev/local-key" $localKey }}

      {{- if $localConfig.podSelector }}
        {{- $_ := set $annotations "generated.network-policies.bigbang.dev/with-local-selector-override" $localConfig.podSelector }}
      {{- end }}

      {{- if and $local.protocol (not (eq $local.protocol "TCP")) }}
        {{- $name = printf "%s-%s" $name (lower $local.protocol) }}
      {{- end }}

      {{- $args := list $ctx $netpol $remoteKey $remoteConfig $name $labels $annotations $local }}
      {{- $netpol = include "bb-common.network-policies.ingress.generate.from-k8s-shorthand" $args | fromYaml }}
      {{- $netpol = merge $netpol (include "bb-common.network-policies.metadata-overrides" (list $localConfig $remoteConfig) | fromYaml) }}
      {{- $netpols = append $netpols $netpol }}
      
      {{- /* Check if authorization policy should be generated - only k8s rules with identity prefix */}}
      {{- if and (contains "@" $remoteKey) (dig "ingress" "generateAuthorizationPolicies" false $ctx.Values.networkPolicies) }}
        {{- $authzPolicy := include "bb-common.authorization-policies.generate.from-network-policy" $args | fromYaml }}
        {{- $authzPolicy := merge $authzPolicy (include "bb-common.network-policies.metadata-overrides" (list $localConfig $remoteConfig) | fromYaml) }}
        {{- $authzpols = append $authzpols $authzPolicy }}
      {{- end }}
    {{- end }}

    {{- /* Process cidr rules */}}
    {{- range $remoteKey, $remoteConfig := dig "from" "cidr" dict $localConfig }}
      {{- $isEnabled := or (and (kindIs "map" $remoteConfig) (dig "enabled" false $remoteConfig)) (and (kindIs "bool" $remoteConfig) $remoteConfig) }}
      {{- if not $isEnabled }}
        {{- continue }}
      {{- end }}

      {{- $netpol := include "bb-common.network-policies.new" (list $local.name $localConfig.podSelector "ingress") | fromYaml }}
      {{- $name := printf "allow-ingress-to-%s" $local.name }}
      {{- $name = include "bb-common.network-policies.prepend-release-name" (list $ctx $name) }}
      {{- $labels := include "bb-common.network-policies.default-labels" "ingress" | fromYaml }}
      {{- $annotations := dict  "generated.network-policies.bigbang.dev/local-key" $localKey }}

      {{- if $localConfig.podSelector }}
        {{- $_ := set $annotations "generated.network-policies.bigbang.dev/with-local-selector-override" $localConfig.podSelector }}
      {{- end }}

      {{- if and $local.protocol (not (eq $local.protocol "TCP")) }}
        {{- $name = printf "%s-%s" $name (lower $local.protocol) }}
      {{- end }}

      {{- $args := list $ctx $netpol $remoteKey $remoteConfig $name $labels $annotations $local }}
      {{- $netpol = include "bb-common.network-policies.ingress.generate.from-cidr-shorthand" $args | fromYaml }}
      {{- $netpol = merge $netpol (include "bb-common.network-policies.metadata-overrides" (list $localConfig $remoteConfig) | fromYaml) }}
      {{- $netpols = append $netpols $netpol }}
    {{- end }}

    {{- /* Process definition rules */}}
    {{- range $remoteKey, $remoteConfig := dig "from" "definition" dict $localConfig }}
      {{- $isEnabled := or (and (kindIs "map" $remoteConfig) (dig "enabled" false $remoteConfig)) (and (kindIs "bool" $remoteConfig) $remoteConfig) }}
      {{- if not $isEnabled }}
        {{- continue }}
      {{- end }}

      {{- $netpol := include "bb-common.network-policies.new" (list $local.name $localConfig.podSelector "ingress") | fromYaml }}
      {{- $name := printf "allow-ingress-to-%s" $local.name }}
      {{- $name = include "bb-common.network-policies.prepend-release-name" (list $ctx $name) }}
      {{- $labels := include "bb-common.network-policies.default-labels" "ingress" | fromYaml }}
      {{- $annotations := dict  "generated.network-policies.bigbang.dev/local-key" $localKey }}

      {{- if $localConfig.podSelector }}
        {{- $_ := set $annotations "generated.network-policies.bigbang.dev/with-local-selector-override" $localConfig.podSelector }}
      {{- end }}

      {{- if and $local.protocol (not (eq $local.protocol "TCP")) }}
        {{- $name = printf "%s-%s" $name (lower $local.protocol) }}
      {{- end }}

      {{- $args := list $ctx $netpol $remoteKey $remoteConfig $name $labels $annotations $local }}
      {{- $netpol = include "bb-common.network-policies.ingress.generate.from-definition" $args | fromYaml }}
      {{- $netpol = merge $netpol (include "bb-common.network-policies.metadata-overrides" (list $localConfig $remoteConfig) | fromYaml) }}
      {{- $netpols = append $netpols $netpol }}
    {{- end }}

    {{- /* Process literal rules */}}
    {{- range $remoteKey, $remoteConfig := dig "from" "literal" dict $localConfig }}
      {{- $isEnabled := dig "enabled" false $remoteConfig }}
      {{- if not $isEnabled }}
        {{- continue }}
      {{- end }}

      {{- $netpol := include "bb-common.network-policies.new" (list $local.name $localConfig.podSelector "ingress") | fromYaml }}
      {{- $name := printf "allow-ingress-to-%s" $local.name }}
      {{- $name = include "bb-common.network-policies.prepend-release-name" (list $ctx $name) }}
      {{- $labels := include "bb-common.network-policies.default-labels" "ingress" | fromYaml }}
      {{- $annotations := dict  "generated.network-policies.bigbang.dev/local-key" $localKey }}

      {{- if $localConfig.podSelector }}
        {{- $_ := set $annotations "generated.network-policies.bigbang.dev/with-local-selector-override" $localConfig.podSelector }}
      {{- end }}

      {{- if and $local.protocol (not (eq $local.protocol "TCP")) }}
        {{- $name = printf "%s-%s" $name (lower $local.protocol) }}
      {{- end }}

      {{- $args := list $ctx $netpol $remoteKey $remoteConfig $name $labels $annotations $local }}
      {{- $netpol = include "bb-common.network-policies.ingress.generate.from-spec-literal" $args | fromYaml }}
      {{- $netpol = merge $netpol (include "bb-common.network-policies.metadata-overrides" (list $localConfig $remoteConfig) | fromYaml) }}
      {{- $netpols = append $netpols $netpol }}
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
