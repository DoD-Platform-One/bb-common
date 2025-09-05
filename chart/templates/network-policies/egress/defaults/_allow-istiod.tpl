{{- define "bb-common.network-policies.egress.defaults.allow-istiod" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "bb-common.network-policies.prepend-release-name" (list . "default-egress-allow-istiod") }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.network-policies.default-labels" "egress" | nindent 4 }}
spec:
  podSelector: {}
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: istio-system
      podSelector:
        matchLabels:
          app: istiod
    ports:
    - port: 15012
      protocol: TCP
  policyTypes:
  - Egress
{{- end }}

