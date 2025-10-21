{{- define "bb-common.istio.authorization-policies.defaults.render" }}
  {{- $ctx := . }}
  {{- $authzpols := list }}

  {{- $istio := $ctx.Values.istio | default dict }}
  {{- $authzPolicies := $istio.authorizationPolicies | default dict }}
  {{- $authzDefaults := $authzPolicies.defaults | default dict }}
  {{- $ingressDefaults := dig "ingress" "defaults" dict $ctx.Values.networkPolicies }}

  {{- $denyAllEnabled := true }}
  {{- if hasKey $authzDefaults "denyAll" }}
    {{- $denyAllEnabled = dig "denyAll" "enabled" true $authzDefaults }}
  {{- else }}
    {{- $denyAllEnabled = dig "denyAll" "enabled" true $ingressDefaults }}
  {{- end }}

  {{- $allowInNamespaceEnabled := true }}
  {{- if hasKey $authzDefaults "allowInNamespace" }}
    {{- $allowInNamespaceEnabled = dig "allowInNamespace" "enabled" true $authzDefaults }}
  {{- else }}
    {{- $allowInNamespaceEnabled = dig "allowInNamespace" "enabled" true $ingressDefaults }}
  {{- end }}

  {{- if $denyAllEnabled }}
    {{- $authzpols = append $authzpols (include "bb-common.istio.authorization-policies.defaults.allow-nothing" $ctx | fromYaml) }}
  {{- end }}
  {{- if $allowInNamespaceEnabled }}
    {{- $authzpols = append $authzpols (include "bb-common.istio.authorization-policies.defaults.allow-all-in-ns" $ctx | fromYaml) }}
  {{- end }}

  {{- if dig "defaultsAsHooks" "enabled" false $ctx.Values.networkPolicies }}
    {{- $defaultHooks := dig "defaultsAsHooks" dict $ctx.Values.networkPolicies }}
    {{- $defaultHookTypes := list "pre-install" "pre-upgrade" "post-delete" }}
    {{- $defaultWeight := -5 }}
    {{- $defaultDeletePolicies := list "hook-succeeded" "before-hook-creation" }}

    {{- $hooks := dig "hooks" $defaultHookTypes $defaultHooks }}
    {{- $weight := dig "weight" $defaultWeight $defaultHooks }}
    {{- $deletePolicies := dig "deletePolicies" $defaultDeletePolicies $defaultHooks }}

    {{- $authzpols = concat $authzpols ((include "bb-common.utils.as-hooks" (list $authzpols $hooks $weight $deletePolicies)) | fromYamlArray) }}
  {{- end }}

  {{- $authzpols | toYaml }}
{{- end }}