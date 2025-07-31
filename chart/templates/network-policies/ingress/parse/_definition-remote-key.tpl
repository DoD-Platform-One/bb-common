{{- define "bb-common.network-policies.ingress.parse.definition-remote-key" }}
  {{- $key := . }}

  {{- /* Parse definition format: just a simple name */}}
  {{- if not (regexMatch `^[\w-]+$` $key) }}
    {{- $expectedFormat := `<definition-name>`}}
    {{- fail (printf "Ingress definition key '%s' does not comply with expected format: %s" $key $expectedFormat) }}
  {{- end }}

  {{- $type := "definition" }}
  {{- $definitionName := $key }}

  {{- dict "type" $type "definitionName" $definitionName | toYaml }}
{{- end }}
