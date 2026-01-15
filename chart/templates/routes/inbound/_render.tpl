{{- define "bb-common.routes.inbound.render" }}
  {{- $ctx := . }}
  {{- $resources := list }}
  {{- $istioAvailable := $ctx.Capabilities.APIVersions.Has "networking.istio.io/v1" }}

  {{- if and $istioAvailable $ctx.Values.routes $ctx.Values.routes.inbound }}
    {{- range $name, $route := $ctx.Values.routes.inbound }}
      {{- if $route.enabled }}

        {{- /* Collect VirtualService object */}}
        {{- $virtualService := include "bb-common.routes.inbound.virtual-service" (list $ctx $name $route) | fromYaml }}
        {{- $resources = append $resources $virtualService }}

        {{- /* Collect ServiceEntry object */}}
        {{- $serviceEntry := include "bb-common.routes.inbound.service-entry" (list $ctx $name $route) | fromYaml }}
        {{- $resources = append $resources $serviceEntry }}

        {{- /* Collect NetworkPolicy and AuthorizationPolicy objects if selector is specified or can be inferred */}}
        {{- $effectiveSelector := $route.selector }}
        {{- if not $effectiveSelector }}
          {{- $effectiveSelector = dict "app.kubernetes.io/name" $name }}
        {{- end }}

        {{- if $effectiveSelector }}
          {{- $routeWithSelector := merge $route (dict "selector" $effectiveSelector) }}

          {{- /* Only create NetworkPolicy if networkPolicies.enabled is true */}}
          {{- if dig "enabled" false ($ctx.Values.networkPolicies | default dict) }}
            {{- $networkPolicy := include "bb-common.routes.inbound.netpol" (list $ctx $name $routeWithSelector) | fromYaml }}
            {{- $resources = append $resources $networkPolicy }}
          {{- end }}

          {{- /* Only create AuthorizationPolicy if istio.authorizationPolicies.enabled is true */}}
          {{- if dig "authorizationPolicies" "enabled" false ($ctx.Values.istio | default dict) }}
            {{- $authorizationPolicy := include "bb-common.routes.inbound.authz" (list $ctx $name $routeWithSelector) | fromYaml }}
            {{- $resources = append $resources $authorizationPolicy }}
          {{- end }}
        {{- end }}

      {{- end }}
    {{- end }}
  {{- end }}

  {{- $resources = include "bb-common.utils.dedupe" $resources | fromYamlArray }}

  {{- range $resource := $resources }}
    {{- print "---" | nindent 0 }}
    {{- $resource | toYaml | nindent 0 }}
  {{- end }}
{{- end }}
