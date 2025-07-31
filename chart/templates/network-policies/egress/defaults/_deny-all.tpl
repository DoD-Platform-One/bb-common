{{- define "bb-common.network-policies.egress.defaults.deny-all" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "bb-common.network-policies.prepend-release-name" (list . "default-egress-deny-all") }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.network-policies.default-labels" "egress" | nindent 4 }}
spec:
  podSelector: {}
  policyTypes:
  - Egress
{{- end }}
