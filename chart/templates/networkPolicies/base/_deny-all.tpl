{{- define "bb-common.netpols.deny-all" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: "{{ .Release.Namespace }}"
  labels:
   {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector: {} # all pods in Release namespace
  policyTypes:
    - Egress
    - Ingress
{{- end }}