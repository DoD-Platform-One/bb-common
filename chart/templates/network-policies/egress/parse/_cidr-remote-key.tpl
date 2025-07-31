{{- define "bb-common.network-policies.egress.parse.cidr-remote-key" }}
  {{- $key := . }}

  {{- /* Parse CIDR format: [<tcp|udp>://]<cidr>[:<<port>|<port-range>|<port-array>>] */}}
  {{- /* INFO: https://regex101.com/r/8ePGPb/1 */}}
  {{- if not (regexMatch `^((tcp|udp)://)?(\d+\.){3}\d+/\d+(:(\d+|\d+-\d+|\[?\d+(,\d+)*\]?))?$` $key) }}
    {{- $expectedFormat := `[<tcp|udp>://]<cidr>[:<<port>|<port-range>|<port-array>>]`}}
    {{- fail (printf "Egress cidr key '%s' does not comply with expected format: %s" $key $expectedFormat) }}
  {{- end }}

  {{- $type := "cidr" }}
  {{- $subject := $key }}

  {{- $parts := splitList "://" $subject }}
  {{- $protocol := "TCP" }}
  {{- $cidrPorts := index $parts 0 }}
  {{- if gt (len $parts) 1 }}
    {{- $protocol = upper (index $parts 0) }}
    {{- $cidrPorts = index $parts 1 }}
  {{- end }}

  {{- $parts = splitList ":" $cidrPorts }}
  {{- $cidr := index $parts 0 }}
  {{- $ports := list }}
  {{- if gt (len $parts) 1 }}
    {{- $ports = include "bb-common.network-policies.parse-ports" (index $parts 1) | fromYamlArray }}
  {{- end }}

  {{- dict "type" $type "cidr" $cidr "ports" $ports "protocol" $protocol | toYaml }}
{{- end }}

