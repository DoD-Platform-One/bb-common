{{- define "bb-common.routes.render" }}
  {{- $ctx := . }}
  {{- $resources := list }}
  {{- $istioAvailable := $ctx.Capabilities.APIVersions.Has "networking.istio.io/v1" }}

  {{- if and $istioAvailable $ctx.Values.routes $ctx.Values.routes.inbound }}
    {{- range $name, $route := $ctx.Values.routes.inbound }}
      {{- if $route.enabled }}

        {{- /* Collect VirtualService object */}}
        {{- $virtualService := include "bb-common.routes.virtual-service" (list $ctx $name $route) | fromYaml }}
        {{- $resources = append $resources $virtualService }}

        {{- /* Collect ServiceEntry object */}}
        {{- $serviceEntry := include "bb-common.routes.service-entry" (list $ctx $name $route) | fromYaml }}
        {{- $resources = append $resources $serviceEntry }}

        {{- /* Collect NetworkPolicy and AuthorizationPolicy objects if selector is specified or can be inferred */}}
        {{- $effectiveSelector := $route.selector }}
        {{- if not $effectiveSelector }}
          {{- $effectiveSelector = dict "app.kubernetes.io/name" $name }}
        {{- end }}

        {{- if $effectiveSelector }}
          {{- $routeWithSelector := merge $route (dict "selector" $effectiveSelector) }}
          {{- $networkPolicy := include "bb-common.routes.netpol" (list $ctx $name $routeWithSelector) | fromYaml }}
          {{- $resources = append $resources $networkPolicy }}

          {{- $authorizationPolicy := include "bb-common.routes.authz" (list $ctx $name $routeWithSelector) | fromYaml }}
          {{- $resources = append $resources $authorizationPolicy }}
        {{- end }}

      {{- end }}
    {{- end }}
  {{- end }}

  {{- range $resource := $resources }}
    {{- print "---" | nindent 0 }}
    {{- $resource | toYaml | nindent 0 }}
  {{- end }}
{{- end }}