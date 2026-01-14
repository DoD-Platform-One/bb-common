{{- define "bb-common.routes.outbound.render" }}
  {{- $ctx := . }}
  {{- $resources := list }}
  {{- $istioAvailable := $ctx.Capabilities.APIVersions.Has "networking.istio.io/v1" }}

  {{- if and $istioAvailable $ctx.Values.routes $ctx.Values.routes.outbound }}
    {{- range $name, $route := $ctx.Values.routes.outbound }}
      {{- if not $route.enabled }}
        {{- continue }}
      {{- end }}

      {{- $serviceEntry := include "bb-common.routes.outbound.service-entry" (list $ctx $name $route) | fromYaml }}
      {{- $resources = append $resources $serviceEntry }}
    {{- end }}
  {{- end }}

  {{- $resources = include "bb-common.utils.dedupe" $resources | fromYamlArray }}

  {{- range $resource := $resources }}
    {{- print "---" | nindent 0 }}
    {{- $resource | toYaml | nindent 0 }}
  {{- end }}
{{- end }}

