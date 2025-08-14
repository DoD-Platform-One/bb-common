{{- define "bb-common.network-policies.ingress.defaults.allow-prometheus-to-istio-sidecar" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "bb-common.network-policies.prepend-release-name" (list . "default-ingress-allow-prometheus-to-istio-sidecar") }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.network-policies.default-labels" "ingress" | nindent 4 }}
spec:
  podSelector: {}
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
      podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
    ports:
    - port: 15020
      protocol: TCP
  policyTypes:
  - Ingress
{{- end }}
