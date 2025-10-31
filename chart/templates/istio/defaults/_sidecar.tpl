{{- define "bb-common.istio.defaults.sidecar" }}
  {{- $ctx := . }}
  {{- $istio := $ctx.Values.istio | default dict }}
  {{- $sidecar := $istio.sidecar | default dict }}
  {{- if and (dig "enabled" false $istio) (dig "enabled" false $sidecar) }}
    {{- /* Build Sidecar resource */}}
    {{- $sidecarResource := dict }}
    {{- $_ := set $sidecarResource "apiVersion" "networking.istio.io/v1" }}
    {{- $_ := set $sidecarResource "kind" "Sidecar" }}

    {{- $metadata := dict "name" (printf "%s-sidecar" $ctx.Release.Name) "namespace" $ctx.Release.Namespace }}
    {{- $_ := set $sidecarResource "metadata" $metadata }}

    {{- $spec := dict }}
    {{- $outboundTrafficPolicy := dict "mode" (dig "outboundTrafficPolicyMode" "REGISTRY_ONLY" $sidecar) }}
    {{- $_ := set $spec "outboundTrafficPolicy" $outboundTrafficPolicy }}
    {{- $_ := set $sidecarResource "spec" $spec }}

    {{- $sidecarResource | toYaml }}
  {{- end }}
{{- end }}
