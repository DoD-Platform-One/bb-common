{{- define "bb-common.network-policies.default-labels" }}
  {{- $direction := . }}
  {{- dict 
    "network-policies.bigbang.dev/source" "bb-common" 
    "network-policies.bigbang.dev/direction" $direction
  | toYaml }}
{{- end }}
