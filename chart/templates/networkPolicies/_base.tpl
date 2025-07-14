{{- define "bb-common.netpols.base" }}
{{- if .Values.networkPolicies.bundled.base.enabled }}
{{/* DNS egress policy */}}
---
{{- include "bb-common.netpols.egress-kube-dns" . }}

{{/* Default deny all policy */}}
---
{{- include "bb-common.netpols.deny-all" . }}

{{/* Intra-namespace communication policy */}}
---
{{- include "bb-common.netpols.allow-intranamespace" . }}
{{- end }}
{{- end }}