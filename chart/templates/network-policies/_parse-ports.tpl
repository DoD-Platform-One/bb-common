{{- define "bb-common.network-policies.parse-ports" }}
  {{- $portSpec := . }}
  {{- $ports := list }}
  
  {{- if (regexMatch `^\[?\d+(,\d+)*\]?$` $portSpec) }}
    {{- $portList := trimPrefix "[" $portSpec | trimSuffix "]" | splitList "," }}
    {{- range $p := $portList }}
      {{- $ports = append $ports (int64 $p) }}
    {{- end }}
  {{- else if contains "-" $portSpec }}
    {{- $range := splitList "-" $portSpec }}
    {{- $start := index $range 0 | int }}
    {{- $end := index $range 1 | int }}
    {{- $iters := add1 (sub $end $start) }}
    {{- range $i := until (int $iters) }}
      {{- $ports = append $ports (add $start $i) }}
    {{- end }}
  {{- else }}
    {{- $ports = append $ports (int64 $portSpec) }}
  {{- end }}
  
  {{- $ports | toYaml }}
{{- end -}}
