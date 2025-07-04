{{- define "bb-common.netpols.base" }}
{{- if .Values.networkPolicies.bundled.base.enabled }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-kube-dns-egress
  namespace: "{{ .Release.Namespace }}"
  labels:
    {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector: {} # all pods in Release namespace
  policyTypes:
    - Egress
  egress:
    - to:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kube-system
      ports:
        - port: 53
          protocol: UDP
        - port: 53
          protocol: TCP
---
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
---
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
{{- end }}