{{- define "bb-common.netpols.egress-tempo" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-tempo-egress
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: tempo
      podSelector:
        matchLabels:
          app.kubernetes.io/name: tempo
    ports:
    - port: 9411
{{- end }}