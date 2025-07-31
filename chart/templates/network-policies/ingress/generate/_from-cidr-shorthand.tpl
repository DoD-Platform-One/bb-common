{{- define "bb-common.network-policies.ingress.generate.from-cidr-shorthand" }}
  {{- $ctx := index . 0 }}
  {{- $netpol := index . 1 }}
  {{- $remoteKey := index . 2 }}
  {{- $remoteValue := index . 3 }}
  {{- $name := index . 4 }}
  {{- $labels := index . 5 }}
  {{- $annotations := index . 6 }}
  {{- $local := index . 7 }}

  {{- $remote := include "bb-common.network-policies.ingress.parse.cidr-remote-key" $remoteKey | fromYaml }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/remote-key" $remoteKey }}
  
  {{- $rule := dict }}
  {{- $ports := list }}
  {{- if $local.ports }}
    {{- $name = printf "%s-%s" $name (lower $local.protocol) }}
    {{- $ports = include "bb-common.network-policies.create-port-array" (list $local.ports $local.hasPortRange $local.protocol) | fromYamlArray }}
    {{- $_ := set $rule "ports" $ports }}
  {{- end }}
  {{- $name = printf "%s-%s" $name (include "bb-common.network-policies.name-ports" (list $ports $local.hasPortRange)) }}

  {{- $ipBlock := dict "cidr" $remote.cidr }}
  {{- if eq $remote.cidr "0.0.0.0/0" }}
    {{- $name = printf "%s-from-anywhere" $name }}
  {{- else }}
    {{- $name = printf "%s-from-cidr-%s" $name ($remote.cidr | replace "." "-" | replace "/" "-") }}
  {{- end }}

  {{- $_ := set $rule "from" (list (dict "ipBlock" $ipBlock)) }}
  {{- $ingress := list $rule }}

  {{- $metadata := dict "name" $name "labels" $labels "annotations" $annotations "namespace" $ctx.Release.Namespace }}
  {{- $_ := set $netpol "metadata" $metadata }}

  {{- $netpol = merge $netpol (dict "spec" (dict "ingress" $ingress)) }}
  {{- $netpol | toYaml }}
{{- end }}
