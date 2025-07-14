{{- define "bb-common.netpols.dynamic" }}
{{/* Kubernetes API access policies */}}
{{- if .Values.networkPolicies.bundled.kubeApiAccess.enabled }}
{{- range (.Values.networkPolicies.bundled.kubeApiAccess.pods | default (list nil)) }}
---
{{- include "bb-common.netpols.egress-kube-api" (dict "root" $ "pod" .) }}
{{- end }}
{{- end }}

{{- if .Values.networkPolicies.bundled.dynamic.enabled }}
{{/* Istio gateway ingress policies */}}
{{- if and .Values.istio .Values.istio.enabled .Values.networkPolicies.bundled.dynamic.ingress }}
{{- range $name, $item := .Values.networkPolicies.bundled.dynamic.ingress }}
---
{{- include "bb-common.netpols.ingress-istio-gateway" (dict "root" $ "item" $item "name" $name) }}
{{- end }}
{{- end }}

{{/* SSO egress policy */}}
{{- if or (and .Values.sso .Values.sso.enabled) (and .Values.authservice .Values.authservice.enabled) }}
---
{{- include "bb-common.netpols.egress-sso" . }}
{{- end }}

{{/* Monitoring metrics ingress policy */}}
{{- if and .Values.monitoring .Values.monitoring.enabled .Values.networkPolicies.bundled.dynamic.metricsPorts }}
---
{{- include "bb-common.netpols.ingress-monitoring-metrics" . }}
{{- end }}

{{/* PostgreSQL database egress policy */}}
{{- if and .Values.networkPolicies.bundled.dynamic.databaseCidrs (eq .Values.postgresql.enabled true) }}
---
{{- include "bb-common.netpols.egress-postgresql" . }}
{{- end }}
{{- end }}
{{- end }}