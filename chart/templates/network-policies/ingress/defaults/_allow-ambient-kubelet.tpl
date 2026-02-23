{{- define "bb-common.network-policies.ingress.defaults.allow-ambient-kubelet" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "bb-common.prepend-release-name" (list . "default-ingress-allow-ambient-kubelet" "networkPolicies") }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.network-policies.default-labels" "ingress" | nindent 4 }}
spec:
  podSelector: {}
  ingress:
  - from:
    - ipBlock:
        cidr: 169.254.7.127/32
  policyTypes:
  - Ingress
{{- end }}