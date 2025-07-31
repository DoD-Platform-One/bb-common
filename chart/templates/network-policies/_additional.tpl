{{- define "bb-common.network-policies.additional" }}
{{- $ctx := . }}
{{- range $netpol := coalesce .Values.networkPolicies.additionalPolicies .Values.networkPolicies.additional list }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ $netpol.name }}
  namespace: {{ $ctx.Release.Namespace }}
  labels:
    network-policies.bigbang.dev/source: bb-common
    {{- if $netpol.labels }}
      {{- $netpol.labels | toYaml | nindent 4 }}
    {{- end }}
  {{- if $netpol.annotations }}
  annotations:
    {{- $netpol.annotations | toYaml | nindent 4 }}
  {{- end }}
spec:
  {{- tpl ($netpol.spec | toYaml) $ctx | nindent 2 }}
{{- end }}
{{- end }}
