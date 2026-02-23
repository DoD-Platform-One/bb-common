{{- define "bb-common.network-policies.ingress.defaults.allow-all-in-ns" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "bb-common.prepend-release-name" (list . "default-ingress-allow-all-in-ns" "networkPolicies") }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.network-policies.default-labels" "ingress" | nindent 4 }}
spec:
  podSelector: {}
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: {{ .Release.Namespace }}
  policyTypes:
  - Ingress
{{- end }}
