{{- define "bb-common.network-policies.ingress.generate.from-definition" }}
  {{- $ctx := index . 0 }}
  {{- $netpol := index . 1 }}
  {{- $remoteKey := index . 2 }}
  {{- $remoteValue := index . 3 }}
  {{- $name := index . 4 }}
  {{- $labels := index . 5 }}
  {{- $annotations := index . 6 }}
  {{- $local := index . 7 }}

  {{- $remote := include "bb-common.network-policies.ingress.parse.definition-remote-key" $remoteKey | fromYaml }}

  {{- $definition := include "bb-common.network-policies.resolve-definition" (list $ctx "ingress" $remote.definitionName) | fromYaml }}
  {{- if $local.ports }}
    {{- $ports := include "bb-common.network-policies.create-port-array" (list $local.ports $local.hasPortRange $local.protocol) | fromYamlArray }}
    {{- $_ := set $definition "ports" $ports }}
    {{- $name = printf "%s-%s" $name (include "bb-common.network-policies.name-ports" (list $ports $local.hasPortRange)) }}
  {{- end }}
  {{- $name = printf "%s-from-%s" $name (lower $remote.definitionName) }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/remote-key" $remoteKey }}

  {{- $metadata := dict "name" $name "labels" $labels "annotations" $annotations "namespace" $ctx.Release.Namespace }}
  {{- $_ := set $netpol "metadata" $metadata }}

  {{- $netpol = merge $netpol (dict "spec" (dict "ingress" (list $definition))) }}
  {{- $netpol | toYaml }}
{{- end }}
