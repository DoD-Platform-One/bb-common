{{- define "bb-common.routes.inbound.virtual-service" }}
  {{- $ctx := index . 0 }}
  {{- $name := index . 1 }}
  {{- $route := index . 2 }}

  {{- $gatewayParts := split "/" (index $route.gateways 0) }}
  {{- $istioNamespace := $gatewayParts._0 }}
  {{- $istioGateway := $gatewayParts._1 }}

  {{- /* Build VirtualService resource */}}
  {{- $vs := dict }}
  {{- $_ := set $vs "apiVersion" "networking.istio.io/v1" }}
  {{- $_ := set $vs "kind" "VirtualService" }}

  {{- $metadata := dict "name" $name "namespace" $ctx.Release.Namespace }}
  {{- if $route.metadata }}
    {{- if $route.metadata.labels }}
      {{- $_ := set $metadata "labels" $route.metadata.labels }}
    {{- end }}
    {{- if $route.metadata.annotations }}
      {{- $_ := set $metadata "annotations" $route.metadata.annotations }}
    {{- end }}
  {{- end }}
  {{- $_ := set $vs "metadata" $metadata }}

  {{- $spec := dict }}
  {{- $_ := set $spec "gateways" $route.gateways }}

  {{- $hosts := list }}
  {{- range $route.hosts }}
    {{- $hosts = append $hosts (tpl . $ctx) }}
  {{- end }}
  {{- $_ := set $spec "hosts" $hosts }}

  {{- if $route.http }}
    {{- $_ := set $spec "http" $route.http }}
  {{- else }}
    {{- $httpRoute := dict "route" (list (dict "destination" (dict "host" (tpl $route.service $ctx) "port" (dict "number" (tpl (toString $route.port) $ctx | int))))) }}
    {{- $_ := set $spec "http" (list $httpRoute) }}
  {{- end }}

  {{- $_ := set $vs "spec" $spec }}
  {{- $vs | toYaml }}
{{- end }}
