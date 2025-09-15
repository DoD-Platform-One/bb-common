{{- define "bb-common.network-policies.egress.defaults.render" }}
  {{- $ctx := . }}
  {{- $netpols := list }}

  {{- $egressDefaults := dig "egress" "defaults" dict $ctx.Values.networkPolicies }}

  {{- if dig "denyAll" "enabled" true $egressDefaults }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.egress.defaults.deny-all" $ctx | fromYaml) }}
  {{- end }}
  {{- if dig "allowInNamespace" "enabled" true $egressDefaults }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.egress.defaults.allow-all-in-ns" $ctx | fromYaml) }}
  {{- end }}
  {{- if dig "allowKubeDns" "enabled" true $egressDefaults }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.egress.defaults.allow-kube-dns" $ctx | fromYaml) }}
  {{- end }}
  {{- if dig "allowIstiod" "enabled" true $egressDefaults }}
    {{- $netpols = append $netpols (include "bb-common.network-policies.egress.defaults.allow-istiod" $ctx | fromYaml) }}
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
