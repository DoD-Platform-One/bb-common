{{- define "bb-common.network-policies.prepend-release-name" }}
  {{- $ctx := index . 0 }}
  {{- $name := index . 1 }}

  {{- if $ctx.Values.networkPolicies.prependReleaseName }}
    {{- printf "%s-%s" (lower $ctx.Release.Name) $name }}
  {{- else }}
    {{- $name }}
  {{- end }}
{{- end }}
