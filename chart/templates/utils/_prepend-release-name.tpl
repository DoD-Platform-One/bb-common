{{- define "bb-common.prepend-release-name" }}
  {{- $ctx := index . 0 }}
  {{- $name := index . 1 }}
  {{- $configKey := index . 2 }}

  {{- $config := index $ctx.Values $configKey | default dict }}
  {{- if dig "prependReleaseName" false $config }}
    {{- printf "%s-%s" (lower $ctx.Release.Name) $name }}
  {{- else }}
    {{- $name }}
  {{- end }}
{{- end }}
