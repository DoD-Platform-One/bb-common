{{- define "bb-common.netpols.conditional" }}
{{- $minioTenant := index .Values "minio-tenant" }}
{{- if .Values.networkPolicies.bundled.conditional.enabled }}
{{/* Helm test egress policy */}}
{{- if and .Values.bbtests .Values.bbtests.enabled }}
---
{{- include "bb-common.netpols.egress-helm-test" . }}
{{- end }}

{{/* Istio control plane policies */}}
{{- if and .Values.istio .Values.istio.enabled }}
---
{{- include "bb-common.netpols.egress-istiod" . }}

{{/* Prometheus monitoring ingress policy */}}
{{- if and .Values.monitoring .Values.monitoring.enabled }}
---
{{- include "bb-common.netpols.ingress-prometheus" . }}
{{- end }}
{{- end }}

{{/* Tempo tracing egress policy */}}
{{- if and .Values.tracing .Values.tracing.enabled }}
---
{{- include "bb-common.netpols.egress-tempo" . }}
{{- end }}

{{/* MinIO operator communication policy */}}
{{- if or (and .Values.minio (or .Values.minio.enabled .Values.minio.install)) (and $minioTenant $minioTenant.enabled) }}
---
{{- include "bb-common.netpols.minio-operator" . }}
{{- end }}
{{- end }}
{{- end }}