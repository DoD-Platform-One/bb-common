{{- define "bb-common.utils.as-hooks" }}
  {{- $resources := index . 0 }}
  {{- $hooks := index . 1 }}
  {{- $weight := index . 2 }}
  {{- $deletePolicies := index . 3 }}

  {{- $hookAnnotation := join "," $hooks }}
  {{- $weightAnnotation := $weight | toString }}
  {{- $deletePolicyAnnotation := join "," $deletePolicies }}

  {{- $resourcesAsHooks := list }}
  {{- range $resource := $resources }}
    {{- $resourceName := dig "metadata" "name" "" $resource }}
    {{- $resourceName = print $resourceName "-as-hook" }}

    {{- $resourceCopy := deepCopy $resource }}
    {{- $resourceAsHook := merge (dict
      "metadata" (dict
        "annotations" (dict
          "helm.sh/hook" $hookAnnotation
          "helm.sh/hook-weight" $weightAnnotation
          "helm.sh/hook-delete-policy" $deletePolicyAnnotation
        )
        "name" $resourceName
      )
    ) $resourceCopy }}

    {{- $resourcesAsHooks = append $resourcesAsHooks $resourceAsHook }}
  {{- end }}

  {{- $resourcesAsHooks | toYaml }}
{{- end }}
