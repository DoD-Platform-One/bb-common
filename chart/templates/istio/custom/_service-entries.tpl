{{- define "bb-common.istio.custom.service-entries" }}
  {{- $ctx := . }}
  {{- $resources := list }}

  {{- $istioEnabled := false }}
  {{- if hasKey $ctx.Values "istio" }}
    {{- $istioEnabled = dig "enabled" false $ctx.Values.istio }}
  {{- end }}

  {{- if $istioEnabled }}
    {{- $customServiceEntries := dig "serviceEntries" "custom" list $ctx.Values.istio }}

    {{- range $entry := $customServiceEntries }}
      {{- $resource := dict }}
      {{- $_ := set $resource "apiVersion" "networking.istio.io/v1" }}
      {{- $_ := set $resource "kind" "ServiceEntry" }}

      {{- $name := include "bb-common.prepend-release-name" (list $ctx $entry.name "istio") | trim }}
      {{- $metadata := dict "name" $name "namespace" $ctx.Release.Namespace }}
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
