{{- define "bb-common.label" }}
source: bb-common
{{- end }}

{{- define "custom.label" -}}
source: custom
{{- end -}}

{{- define "bb-common.metadataExclude" -}}
{{- $cidr := . -}}
{{- if eq $cidr "0.0.0.0/0"}}
except:
  - 169.254.169.254/32
{{- end }}
{{- end -}}

{{/*
  Splits a string like "grafana.monitoring" into a dict with keys "pod" and "namespace"
  Usage: {{ include "bb-common.splitPodAndNamespace" "grafana.monitoring" | fromYaml }}
*/}}
{{- define "bb-common.splitPodAndNamespace" -}}
{{- $parts := split "." . }}
{{- if eq (len $parts) 2 }}
pod: {{ $parts._0 }}
namespace: {{ $parts._1 }}
{{- else }}
{{ fail (printf "Invalid format for pod.namespace: %s" .) }}
{{- end }}
{{- end }}