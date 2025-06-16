{{- define "bb-common.netpols.additional" }}
{{- range $policy := .Values.networkPolicies.additionalPolicies -}}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ $policy.name }}
  labels:
    {{- include "custom.label" . | nindent 4 }}
spec:
  {{ tpl ($policy.spec | toYaml) $ | nindent 2 }}
{{- end }}
{{- end }}