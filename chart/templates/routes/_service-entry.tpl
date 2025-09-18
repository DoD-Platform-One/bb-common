{{- define "bb-common.routes.service-entry" }}
  {{- $ctx := index . 0 }}
  {{- $name := index . 1 }}
  {{- $route := index . 2 }}

  {{- /* Build ServiceEntry resource */}}
  {{- $se := dict }}
  {{- $_ := set $se "apiVersion" "networking.istio.io/v1beta1" }}
  {{- $_ := set $se "kind" "ServiceEntry" }}

  {{- $metadata := dict "name" (printf "%s-service-entry" $name) "namespace" $ctx.Release.Namespace }}
  {{- if $route.metadata }}
    {{- if $route.metadata.labels }}
      {{- $_ := set $metadata "labels" $route.metadata.labels }}
    {{- end }}
    {{- if $route.metadata.annotations }}
      {{- $_ := set $metadata "annotations" $route.metadata.annotations }}
    {{- end }}
  {{- end }}
  {{- $_ := set $se "metadata" $metadata }}

  {{- $spec := dict }}
  {{- $hosts := list }}
  {{- range $route.hosts }}
    {{- $hosts = append $hosts (tpl . $ctx) }}
  {{- end }}
  {{- $_ := set $spec "hosts" $hosts }}
  {{- $_ := set $spec "location" "MESH_EXTERNAL" }}
  {{- $_ := set $spec "resolution" "DNS" }}

  {{- $ports := list }}
  {{- $httpsPort := dict "name" "https" "number" 443 "protocol" "HTTPS" }}
  {{- $ports = append $ports $httpsPort }}
  {{- $_ := set $spec "ports" $ports }}

  {{- $_ := set $se "spec" $spec }}
  {{- $se | toYaml }}
{{- end }}