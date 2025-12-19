{{- define "bb-common.routes.outbound.service-entry" }}
  {{- $ctx := index . 0 }}
  {{- $name := index . 1 }}
  {{- $route := index . 2 }}

  {{- if not $route.hosts }}
    {{- fail (printf "Route '%s' must define at least one host for outbound ServiceEntry" $name) }}
  {{- end }}

  {{- $hosts := list }}
  {{- range $host := $route.hosts }}
    {{- $hosts = append $hosts (tpl $host $ctx) }}
  {{- end }}

  {{- $ports := list }}
  {{- range $port := $route.ports }}
    {{- $portNumber := $port.number }}
    {{- if kindIs "string" $portNumber }}
      {{- $portNumber = tpl $portNumber $ctx | int }}
    {{- end }}

    {{- $port := dict 
      "name" $port.name 
      "number" $portNumber 
      "protocol" $port.protocol 
    }}

    {{- $ports = append $ports $port }}
  {{- end }}

  {{- if not $ports }}
    {{- $httpsPort := dict 
      "name" "https" 
      "number" 443 
      "protocol" "HTTPS" 
    }}
    {{- $ports = append $ports $httpsPort }}
  {{- end }}

  {{- $location := $route.location | default "MESH_EXTERNAL" }}
  {{- $resolution := $route.resolution | default "DNS" }}

  {{- $spec := dict 
    "hosts" $hosts
    "location" $location
    "resolution" $resolution
    "ports" $ports
  }}

  {{- $labels := dig "metadata" "labels" dict $route }}
  {{- $annotations := dig "metadata" "annotations" dict $route }}

  {{- $_ := set $labels "service-entries.bigbang.dev/source" "bb-common" }}
  {{- $_ := set $annotations "outbound.service-entries.generated.bigbang.dev/from-route-name" $name }}

  {{- $name := printf "%s-%s" $name (ternary "external" "internal" (eq $location "MESH_EXTERNAL")) }}

  {{- $metadata := dict 
    "labels" $labels
    "annotations" $annotations
    "name" $name
    "namespace" $ctx.Release.Namespace
  }}

  {{- $serviceEntry := dict
    "apiVersion" "networking.istio.io/v1"
    "kind" "ServiceEntry"
    "metadata" $metadata
    "spec" $spec
  }}

  {{- $serviceEntry | toYaml }}
{{- end }}

