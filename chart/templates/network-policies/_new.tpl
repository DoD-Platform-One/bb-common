{{- define "bb-common.network-policies.new" }}
  {{- $podName := index . 0 }}
  {{- $selector := index . 1 }}
  {{- $direction := index . 2 }}

  {{- if not $selector }}
    {{- if eq $podName "*" }}
      {{- $selector = dict }}
    {{- else }}
      {{- $selector = dict "matchLabels" (dict "app.kubernetes.io/name" $podName) }}
    {{- end }}
  {{- end }}

  {{- dict 
    "apiVersion" "networking.k8s.io/v1" 
    "kind" "NetworkPolicy" 
    "spec" (dict 
      "podSelector" $selector 
      "policyTypes" (list 
        (title $direction)
      )
    ) | toYaml 
  }}
{{- end }}
