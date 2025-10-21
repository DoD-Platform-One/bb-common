{{- define "bb-common.istio.defaults.sidecar" }}
  {{- $ctx := . }}
  {{- $istio := $ctx.Values.istio | default dict }}
  {{- $hardened := $istio.hardened | default dict }}
  {{- if and (dig "enabled" false $istio) (dig "enabled" false $hardened) }}
    {{- /* Build Sidecar resource */}}
    {{- $sidecar := dict }}
    {{- $_ := set $sidecar "apiVersion" "networking.istio.io/v1" }}
    {{- $_ := set $sidecar "kind" "Sidecar" }}

    {{- $metadata := dict "name" (printf "%s-sidecar" $ctx.Release.Name) "namespace" $ctx.Release.Namespace }}
    {{- $_ := set $sidecar "metadata" $metadata }}

    {{- $spec := dict }}
    {{- $outboundTrafficPolicy := dict "mode" (dig "outboundTrafficPolicyMode" "REGISTRY_ONLY" $hardened) }}
    {{- $_ := set $spec "outboundTrafficPolicy" $outboundTrafficPolicy }}
    {{- $_ := set $sidecar "spec" $spec }}

    {{- $sidecar | toYaml }}
  {{- end }}
{{- end }}
