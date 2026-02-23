{{- define "bb-common.istio.authorization-policies.additional" }}
{{- $ctx := . }}
{{- $authzpols := list }}
{{- $istio := .Values.istio | default dict }}
{{- $authzPolicies := $istio.authorizationPolicies | default dict }}
{{- $additionalPolicies := coalesce (dig "additionalPolicies" nil $authzPolicies) (dig "additional" nil $authzPolicies) dict }}
{{- range $policyName, $policyConfig := $additionalPolicies }}
  {{- if dig "enabled" true $policyConfig }}
    {{- $policy := dict }}
    {{- $_ := set $policy "apiVersion" "security.istio.io/v1" }}
    {{- $_ := set $policy "kind" "AuthorizationPolicy" }}
    {{- $name := default $policyName $policyConfig.name }}
    {{- $name = include "bb-common.prepend-release-name" (list $ctx $name "istio") | trim }}
    {{- $metadata := dict "name" $name "namespace" $ctx.Release.Namespace }}
    {{- $labels := dict "authorization-policies.bigbang.dev/source" "bb-common" }}
    {{- if $policyConfig.labels }}
      {{- $labels = merge $labels $policyConfig.labels }}
    {{- end }}
    {{- $_ := set $metadata "labels" $labels }}
    {{- if $policyConfig.annotations }}
      {{- $_ := set $metadata "annotations" $policyConfig.annotations }}
    {{- end }}
    {{- $_ := set $policy "metadata" $metadata }}
    {{- $_ := set $policy "spec" $policyConfig.spec }}
    {{- $authzpols = append $authzpols $policy }}
  {{- end }}
{{- end }}
{{- $authzpols | toYaml }}
{{- end }}