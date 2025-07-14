{{- define "bb-common.netpols.egress-helm-test" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-helm-test-egress
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector:
    matchLabels:
      helm-test: enabled
  policyTypes:
  - Egress
  egress:
  - {}
{{- end }}