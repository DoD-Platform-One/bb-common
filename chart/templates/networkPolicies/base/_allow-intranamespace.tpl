{{- define "bb-common.netpols.allow-intranamespace" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-intranamespace
  namespace: "{{ .Release.Namespace }}"
  labels:
    {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector: {} # all pods in Release namespace
  ingress:
    - from: 
      - podSelector: {} # all pods in Release namespace
  egress:
    - to: 
      - podSelector: {} # all pods in Release namespace
  policyTypes:
    - Egress
    - Ingress
{{- end }}