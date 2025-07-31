{{- define "bb-common.network-policies.egress.generate.from-cidr-shorthand" }}
  {{- $ctx := index . 0 }}
  {{- $netpol := index . 1 }}
  {{- $remoteKey := index . 2 }}
  {{- $remoteValue := index . 3 }}
  {{- $name := index . 4 }}
  {{- $labels := index . 5 }}
  {{- $annotations := index . 6 }}
  {{- $local := index . 7 }}

  {{- $remote := include "bb-common.network-policies.egress.parse.cidr-remote-key" $remoteKey | fromYaml }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/remote-key" $remoteKey }}

  {{- $rule := dict }}

  {{- $ipBlock := dict "cidr" $remote.cidr }}
  {{- if eq $remote.cidr "0.0.0.0/0" }}
    {{- $name = printf "%s-to-anywhere" $name }}
  {{- else }}
    {{- $name = printf "%s-to-cidr-%s" $name ($remote.cidr | replace "." "-" | replace "/" "-") }}
  {{- end }}

  {{- $exclusions := dig "egress" "excludeCIDRs" (list "169.254.169.254/32") $ctx.Values.networkPolicies }}
  {{- $except := list }}
  {{- range $exclusion := $exclusions }}
    {{- if eq "true" (include "bb-common.utils.cidr-contains" (list $remote.cidr $exclusion)) }}
      {{- $except = append $except $exclusion }}
    {{- end }}
  {{- end }}
  {{- if $except }}
    {{- $_ := set $ipBlock "except" $except }}
  {{- end }}

  {{- $_ := set $rule "to" (list (dict "ipBlock" $ipBlock)) }}
  {{- $ports := list }}
  {{- if $remote.ports }}
    {{- $name = printf "%s-%s" $name (lower $remote.protocol) }}
    {{- $ports = include "bb-common.network-policies.create-port-array" (list $remote.ports $remote.hasPortRange $remote.protocol) | fromYamlArray }}
    {{- $_ := set $rule "ports" $ports }}
  {{- end }}
  {{- $name = printf "%s-%s" $name (include "bb-common.network-policies.name-ports" (list $ports $remote.hasPortRange)) }}

  {{- $egress := list $rule }}

  {{- $metadata := dict "name" $name "labels" $labels "annotations" $annotations "namespace" $ctx.Release.Namespace }}
  {{- $_ := set $netpol "metadata" $metadata }}

  {{- $netpol = merge $netpol (dict "spec" (dict "egress" $egress)) }}
  {{- $netpol | toYaml }}
{{- end }}

