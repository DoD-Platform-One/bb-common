{{- define "bb-common.network-policies.inject-hbone-ports" }}
  {{- $netpols := index . 0 }}
  {{- $direction := index . 1 }}

  {{- $hbonePort := dict
    "port" 15008
    "protocol" "TCP"
  }}

  {{- range $netpol := $netpols }}
    {{- $rules := dig "spec" $direction false $netpol }}

    {{- if not $rules }}
      {{- continue }}
    {{- end }}

    {{- range $rule := $rules }}
      {{- if or (not (hasKey $rule "ports")) (empty $rule.ports) }}
        {{- continue }}
      {{- end }}
      {{- $hasHBonePort := false }}

      {{- range $port := $rule.ports }}
        {{- if and (eq (int $port.port) (int $hbonePort.port)) (eq $port.protocol $hbonePort.protocol) }}
          {{- $hasHBonePort = true }}
        {{- end }}
      {{- end }}

      {{- if not $hasHBonePort }}
        {{- $ports := $rule.ports }}
        {{- $ports = append $ports $hbonePort }}
        {{- $_ := set $rule "ports" $ports }}
        {{- $_ := merge $netpol (dict "metadata" (dict "labels" (dict "ambient.istio.network-policies.bigbang.dev/hbone-injected" "true"))) }}
      {{- end }}
    {{- end }}
  {{- end}}

  {{- $netpols | toYaml }}
{{- end }}
