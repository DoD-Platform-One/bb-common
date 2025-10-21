{{- define "bb-common.istio.custom.service-entries" }}
  {{- $ctx := . }}
  {{- $resources := list }}

  {{- $istioEnabled := false }}
  {{- if hasKey $ctx.Values "istio" }}
    {{- $istioEnabled = dig "enabled" false $ctx.Values.istio }}
  {{- end }}

  {{- $hardenedEnabled := false }}
  {{- if hasKey $ctx.Values "istio" }}
    {{- if hasKey $ctx.Values.istio "hardened" }}
      {{- $hardenedEnabled = dig "enabled" false $ctx.Values.istio.hardened }}
    {{- end }}
  {{- end }}

  {{- if and $istioEnabled $hardenedEnabled }}
    {{- $customServiceEntries := list }}
    {{- if hasKey $ctx.Values.istio.hardened "customServiceEntries" }}
      {{- $customServiceEntries = $ctx.Values.istio.hardened.customServiceEntries }}
    {{- end }}
    {{- range $entry := $customServiceEntries }}
      {{- $resource := dict }}
      {{- $_ := set $resource "apiVersion" "networking.istio.io/v1" }}
      {{- $_ := set $resource "kind" "ServiceEntry" }}

      {{- $metadata := dict "name" $entry.name "namespace" $ctx.Release.Namespace }}
      {{- if $entry.labels }}
        {{- $_ := set $metadata "labels" $entry.labels }}
      {{- end }}
      {{- if $entry.annotations }}
        {{- $_ := set $metadata "annotations" $entry.annotations }}
      {{- end }}
      {{- $_ := set $resource "metadata" $metadata }}

      {{- $_ := set $resource "spec" $entry.spec }}

      {{- $resources = append $resources $resource }}
    {{- end }}
  {{- end }}

  {{- $resources | toYaml }}
{{- end }}
