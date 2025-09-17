{{- define "bb-common.network-policies.egress.generate.from-k8s-shorthand" }}
  {{- $ctx := index . 0 }}
  {{- $netpol := index . 1 }}
  {{- $remoteKey := index . 2 }}
  {{- $remoteValue := index . 3 }}
  {{- $name := index . 4 }}
  {{- $labels := index . 5 }}
  {{- $annotations := index . 6 }}

  {{- $remote := include "bb-common.network-policies.egress.parse.k8s-remote-key" $remoteKey | fromYaml }}
  {{- $_ := set $annotations "generated.network-policies.bigbang.dev/remote-key" $remoteKey }}

  {{- $rule := dict }}

  {{- $namespaceSelector := dict "matchLabels" (dict "kubernetes.io/metadata.name" $remote.namespace) }}
  {{- if eq $remote.namespace "*" }}
    {{- $namespaceSelector = dict }}
    {{- $name = printf "%s-to-any-ns" $name }}
  {{- else }}
    {{- $name = printf "%s-to-ns-%s" $name $remote.namespace }}
  {{- end }}
  {{- $podSelector := dict }}

  {{- if and $remote.pod (not (eq $remote.pod "*")) }}
    {{- $podSelector = dict "matchLabels" (dict "app.kubernetes.io/name" $remote.pod) }}
    {{- $name = printf "%s-pod-%s" $name $remote.pod }}
  {{- else }}
    {{- $name = printf "%s-any-pod" $name }}
  {{- end }}

  {{- if kindIs "map" $remoteValue }}
    {{- $selectorOverrides := dict }}

    {{- if $remoteValue.podSelector }}
      {{- $podSelector = $remoteValue.podSelector }}
      {{- $_ := set $selectorOverrides "podSelector" $podSelector }}
    {{- end }}

    {{- if $remoteValue.namespaceSelector }}
      {{- $namespaceSelector = $remoteValue.namespaceSelector }}
      {{- $_ := set $selectorOverrides "namespaceSelector" $namespaceSelector }}
    {{- end }}

    {{- if $selectorOverrides }}
      {{- $_ := set $annotations "generated.network-policies.bigbang.dev/with-remote-selector-overrides" ($selectorOverrides | toYaml) }}
    {{- end }}
  {{- end }}

  {{- $selector := dict "namespaceSelector" $namespaceSelector "podSelector" $podSelector }}

  {{- $ports := list }}
  {{- if $remote.ports }}
    {{- $name = printf "%s-%s" $name (lower $remote.protocol) }}
    {{- $ports = include "bb-common.network-policies.create-port-array" (list $remote.ports $remote.hasPortRange $remote.protocol) | fromYamlArray }}
    {{- $_ := set $rule "ports" $ports }}
  {{- end }}
  {{- $name = printf "%s-%s" $name (include "bb-common.network-policies.name-ports" (list $ports $remote.hasPortRange)) }}

  {{- $_ := set $rule "to" (list $selector) }}
  {{- $egress := list $rule }}
  {{- $netpol = merge $netpol (dict "spec" (dict "egress" $egress)) }}

  {{- $metadata := dict "name" $name "labels" $labels "annotations" $annotations "namespace" $ctx.Release.Namespace }}
  {{- $_ := set $netpol "metadata" $metadata }}

  {{- $netpol | toYaml }}
{{- end }}
