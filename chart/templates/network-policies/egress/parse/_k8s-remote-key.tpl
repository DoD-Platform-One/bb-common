{{- define "bb-common.network-policies.egress.parse.k8s-remote-key" }}
  {{- $key := . }}

  {{- /* Parse k8s format: [<tcp|udp>://]<namespace>[/<pod>][:<<port>|<port-range>|<port-array>>] */}}
  {{- /* INFO: https://regex101.com/r/d4dwSR/1 */}}
  {{- if not (regexMatch `^((tcp|udp)://)?([A-Za-z0-9-]+|\*)(/([A-Za-z0-9-]+|\*))?(:(\d+|\d+-\d+|\[?\d+(,\d+)*\]?))?$` $key) }}
    {{- $expectedFormat := `[<tcp|udp>://]<namespace>[/<pod>][:<<port>|<port-range>|<port-array>>]`}}
    {{- fail (printf "Egress k8s key '%s' does not comply with expected format: %s" $key $expectedFormat) }}
  {{- end }}

  {{- $type := "k8s" }}
  {{- $subject := $key }}

  {{- $parts := splitList "://" $subject }}
  {{- $protocol := "TCP" }}
  {{- $nsPodPorts := index $parts 0 }}
  {{- if gt (len $parts) 1 }}
    {{- $protocol = upper (index $parts 0) }}
    {{- $nsPodPorts = index $parts 1 }}
  {{- end }}

  {{- $parts = splitList ":" $nsPodPorts }}
  {{- $nsPod := index $parts 0 }}
  {{- $ports := list }}
  {{- $hasPortRange := false }}
  {{- if gt (len $parts) 1 }}
    {{- $ports = include "bb-common.network-policies.parse-ports" (index $parts 1) | fromYamlArray }}
    {{- $hasPortRange = contains "-" (index $parts 1) }}
  {{- end }}

  {{- $parts := splitList "/" $nsPod }}
  {{- $namespace := index $parts 0 }}
  {{- $pod := "" }}
  {{- if gt (len $parts) 1 }}
    {{- $pod = index $parts 1 }}
  {{- end }}
  
  {{- dict "type" $type "namespace" $namespace "pod" $pod "ports" $ports "protocol" $protocol "hasPortRange" $hasPortRange | toYaml }}
{{- end }}

