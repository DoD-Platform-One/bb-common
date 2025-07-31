{{- define "bb-common.network-policies.ingress.parse.cidr-remote-key" }}
  {{- $key := . }}

  {{- /* Parse CIDR format: <cidr> */}}
  {{- if not (regexMatch `^(\d+\.){3}\d+/\d+$` $key) }}
    {{- $expectedFormat := `<cidr>`}}
    {{- fail (printf "Ingress cidr key '%s' does not comply with expected format: %s" $key $expectedFormat) }}
  {{- end }}

  {{- $type := "cidr" }}
  {{- $cidr := $key }}

  {{- dict "type" $type "cidr" $cidr | toYaml }}
{{- end }}
