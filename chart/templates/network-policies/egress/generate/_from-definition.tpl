{{- define "bb-common.network-policies.egress.generate.from-definition" }}
  {{- $ctx := index . 0 }}
  {{- $netpol := index . 1 }}
  {{- $remoteKey := index . 2 }}
  {{- $remoteValue := index . 3 }}
  {{- $name := index . 4 }}
  {{- $labels := index . 5 }}
  {{- $annotations := index . 6 }}
  {{- $local := index . 7 }}

  {{- $remote := include "bb-common.network-policies.egress.parse.definition-remote-key" $remoteKey | fromYaml }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/remote-key" $remoteKey }}

  {{- $definition := include "bb-common.network-policies.resolve-definition" (list $ctx "egress" $remote.definitionName) | fromYaml }}
  {{- $name = printf "%s-to-%s" $name (lower $remote.definitionName) }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/from-definition" $remote.definitionName }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/remote-key" $remoteKey }}

  {{- $metadata := dict "name" $name "labels" $labels "annotations" $annotations "namespace" $ctx.Release.Namespace }}
  {{- $_ := set $netpol "metadata" $metadata }}

  {{- $netpol = merge $netpol (dict "spec" (dict "egress" (list $definition))) }}
  {{- $netpol | toYaml }}
{{- end }}
