{{- define "bb-common.network-policies.ingress.parse.k8s-remote-key" }}
  {{- $key := . }}

  {{- /* Parse k8s format: [<identity>@]<namespace>[/<pod>] */}}
  {{- /* INFO: https://regex101.com/r/h0D5SI/1 */}}
  {{- if not (regexMatch `^([A-Za-z0-9-]+@)?([A-Za-z0-9-]+|\*)(/([A-Za-z0-9-]+|\*))?$` $key) }}
    {{- $expectedFormat := `[<identity>@]<namespace>[/<pod>]`}}
    {{- fail (printf "Ingress k8s key '%s' does not comply with expected format: %s" $key $expectedFormat) }}
  {{- end }}

  {{- $type := "k8s" }}
  {{- $subject := $key }}
  {{- $identity := "" }}

  {{- if contains "@" $subject }}
    {{- $identityParts := splitList "@" $subject }}
    {{- $identity = index $identityParts 0 }}
    {{- $subject = index $identityParts 1 }}
  {{- end }}

  {{- $parts := splitList "/" $subject }}
  {{- $namespace := index $parts 0 }}
  {{- $pod := "" }}
  {{- if gt (len $parts) 1 }}
    {{- $pod = index $parts 1 }}
  {{- end }}
  
  {{- $result := dict "type" $type "namespace" $namespace "pod" $pod }}
  {{- if $identity }}
    {{- $_ := set $result "identity" $identity }}
  {{- end }}
  {{- $result | toYaml }}
{{- end }}
