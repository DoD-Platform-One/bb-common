{{- define "bb-common.istio.custom.authorization-policies" }}
  {{- $ctx := . }}
  {{- $resources := list }}

  {{- $istioEnabled := false }}
  {{- if hasKey $ctx.Values "istio" }}
    {{- $istioEnabled = dig "enabled" false $ctx.Values.istio }}
  {{- end }}

  {{- if $istioEnabled }}
    {{- $customAuthzPolicies := dig "authorizationPolicies" "custom" list $ctx.Values.istio }}

    {{- range $policy := $customAuthzPolicies }}
      {{- $resource := dict }}
      {{- $_ := set $resource "apiVersion" "security.istio.io/v1" }}
      {{- $_ := set $resource "kind" "AuthorizationPolicy" }}

      {{- $metadata := dict "name" $policy.name "namespace" $ctx.Release.Namespace }}
      {{- if $policy.labels }}
        {{- $_ := set $metadata "labels" $policy.labels }}
      {{- end }}
      {{- if $policy.annotations }}
        {{- $_ := set $metadata "annotations" $policy.annotations }}
      {{- end }}
      {{- $_ := set $resource "metadata" $metadata }}

      {{- $_ := set $resource "spec" $policy.spec }}

      {{- $resources = append $resources $resource }}
    {{- end }}
  {{- end }}

  {{- $resources | toYaml }}
{{- end }}
