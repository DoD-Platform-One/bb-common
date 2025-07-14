{{- define "bb-common.netpols.egress-kube-api" }}
{{- $suffix := (ternary .pod "all" (not (empty .pod))) }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-kube-api-egress-{{ $suffix }}
  namespace: {{ .root.Release.Namespace }}
  labels:
    {{- include "bb-common.label" .root  | indent 4}}
spec:
  podSelector:
    {{- if .pod }}
    matchLabels:
      app.kubernetes.io/name: {{ .pod }}
    {{- else }}
    {}
    {{- end }}
  policyTypes:
  - Egress
  egress:
  - to:
  {{- range .root.Values.networkPolicies.bundled.kubeApiAccess.controlPlaneCidrs }}
    - ipBlock:
        cidr: {{ . }}
        {{- include "bb-common.metadataExclude" . | indent 8 }}
  {{- end -}}
{{- end }}
