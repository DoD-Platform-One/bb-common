{{- define "bb-common.network-policies.egress.defaults.allow-all-in-ns" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "bb-common.network-policies.prepend-release-name" (list . "default-egress-allow-all-in-ns") }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.network-policies.default-labels" "egress" | nindent 4 }}
spec:
  podSelector: {}
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: {{ .Release.Namespace }}
  policyTypes:
  - Egress
{{- end }}
