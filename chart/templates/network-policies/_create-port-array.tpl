{{- define "bb-common.network-policies.create-port-array" }}
  {{- $portNumbers := index . 0 }}
  {{- $isRange := index . 1 }}
  {{- $protocol := index . 2 }}

  {{- $ports := list }}

  {{- if $isRange }}
    {{- $startPort := index $portNumbers 0 }}
    {{- $endPort := index $portNumbers (sub (len $portNumbers) 1) }}
    {{- $ports = append $ports (dict "port" $startPort "endPort" $endPort "protocol" $protocol) }}
  {{- else }}
    {{- range $portNumber := $portNumbers }}
      {{- $ports = append $ports (dict "port" $portNumber "protocol" $protocol) }}
    {{- end }}
  {{- end }}

  {{- $ports | toYaml }}
{{- end }}
