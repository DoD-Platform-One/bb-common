{{- define "bb-common.network-policies.ingress.defaults.render" }}
  {{- $ctx := . }}
  {{- $netpols := list }}

  {{- $ingressDefaults := dig "ingress" "defaults" dict $ctx.Values.networkPolicies }}

  {{- if dig "denyAll" "enabled" true $ingressDefaults }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.ingress.defaults.deny-all" $ctx | fromYaml) }}
  {{- end }}
  {{- if dig "allowInNamespace" "enabled" true $ingressDefaults }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.ingress.defaults.allow-all-in-ns" $ctx | fromYaml) }}
  {{- end }}
  {{- if dig "allowPrometheusToIstioSidecar" "enabled" true $ingressDefaults }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.ingress.defaults.allow-prometheus-to-istio-sidecar" $ctx | fromYaml) }}
  {{- end }}

  {{- if dig "ambient" "enabled" false ($ctx.Values.istio | default dict) }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.ingress.defaults.allow-ambient-kubelet" $ctx | fromYaml) }}
  {{- end }}

  {{- if dig "defaultsAsHooks" "enabled" false $ctx.Values.networkPolicies }}
    {{- $defaultHooks := dig "defaultsAsHooks" dict $ctx.Values.networkPolicies }}
    {{- $defaultHookTypes := list "pre-install" "pre-upgrade" "post-delete" }}
    {{- $defaultWeight := -5 }}
    {{- $defaultDeletePolicies := list "hook-succeeded" "before-hook-creation" }}

    {{- $hooks := dig "hooks" $defaultHookTypes $defaultHooks }}
    {{- $weight := dig "weight" $defaultWeight $defaultHooks }}
    {{- $deletePolicies := dig "deletePolicies" $defaultDeletePolicies $defaultHooks }}

    {{- $netpols = concat $netpols ((include "bb-common.utils.as-hooks" (list $netpols $hooks $weight $deletePolicies)) | fromYamlArray) }}
  {{- end }}

  {{- $netpols | toYaml }}
{{- end }}
