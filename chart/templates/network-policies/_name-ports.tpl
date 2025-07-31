{{- define "bb-common.network-policies.name-ports" }}
  {{- $ports := index . 0 }}
  {{- $hasPortRange := index . 1 }}

  {{- if not $ports }}
    {{- print "any-port" }}
  {{- else }}
    {{- print "port" }}
    {{- if $hasPortRange }}
      {{- print "s" -}}
      {{- $beginPort := (index $ports 0).port }}
      {{- $endPort := (index $ports 0).endPort }}
      {{- printf "-%v" $beginPort }}
      {{- printf "-thru-%v" $endPort }}
    {{- else -}}
      {{- if gt (len $ports) 1 }}
        {{- print "s" -}}
      {{- end -}}
      {{- range $i, $p := $ports }}
        {{- printf "-%v" $p.port }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
