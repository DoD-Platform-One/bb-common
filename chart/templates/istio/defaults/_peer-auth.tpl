{{- define "bb-common.istio.defaults.peer-auth" }}
  {{- $ctx := . }}
  {{- $istio := $ctx.Values.istio | default dict }}
  {{- if dig "enabled" false $istio }}
    {{- /* Build PeerAuthentication resource */}}
    {{- $peerAuth := dict }}
    {{- $_ := set $peerAuth "apiVersion" "security.istio.io/v1" }}
    {{- $_ := set $peerAuth "kind" "PeerAuthentication" }}

    {{- $metadata := dict "name" "default-peer-auth" "namespace" $ctx.Release.Namespace }}
    {{- $_ := set $peerAuth "metadata" $metadata }}

    {{- $spec := dict }}
    {{- $mtls := dict "mode" (dig "mtls" "mode" "STRICT" $istio) }}
    {{- $_ := set $spec "mtls" $mtls }}
    {{- $_ := set $peerAuth "spec" $spec }}

    {{- $peerAuth | toYaml }}
  {{- end }}
{{- end }}
