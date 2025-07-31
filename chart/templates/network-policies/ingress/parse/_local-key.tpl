{{- define "bb-common.network-policies.ingress.parse.local-key" }}
  {{- $key := . }}

  {{- /* If you edit this regex, please update the regex101 example. */}}
  {{- /* INFO: https://regex101.com/r/xa7TmZ/1*/}}
  {{- if not (regexMatch `^((tcp|udp)://)?[\w-]+(:(\[?\d+(,\d+)*\]?|\d+|\d+-\d+))?$` $key) }}
    {{- $expectedFormat := "[<udp|tcp>://]<pod-name>[:<<port>|<port-range>|<port-array>>]" }}
    {{- fail (printf "Ingress local key '%s' does not comply with expected format: %s" $key $expectedFormat) }}
  {{- end }}

  {{- $parts := splitList "://" . }}
  {{- $protocol := "TCP" }}
  {{- $namePort := index $parts 0 }}
  {{- if gt (len $parts) 1 }}
    {{- $protocol = upper (index $parts 0) }}
    {{- $namePort = index $parts 1 }}
  {{- end }}

  {{- $parts := splitList ":" $namePort }}
  {{- $podName := index $parts 0 }}
  {{- $ports := list }}
  {{- $hasPortRange := false }}
  {{- if gt (len $parts) 1 }}
    {{- $portSpec := index $parts 1 }}
    {{- $ports = include "bb-common.network-policies.parse-ports" $portSpec | fromYamlArray }}
    {{- $hasPortRange = contains "-" $portSpec }}
  {{- end }}

  {{- dict "name" $podName "protocol" $protocol "ports" $ports "hasPortRange" $hasPortRange | toYaml }}
{{- end }}

