{{- define "bb-common.network-policies.ingress.defaults.deny-all" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "bb-common.network-policies.prepend-release-name" (list . "default-ingress-deny-all") }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.network-policies.default-labels" "ingress" | nindent 4 }}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
{{- end }}
