{{- define "bb-common.netpols.conditional" }}
{{- if .Values.networkPolicies.bundled.conditional.enabled }}
{{- if and .Values.bbtests .Values.bbtests.enabled }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-helm-test-egress
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector:
    matchLabels:
      helm-test: enabled
  policyTypes:
  - Egress
  egress:
  - {}
{{- end }}
{{- if and .Values.istio .Values.istio.enabled }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-istiod-egress
  namespace: "{{ .Release.Namespace }}"
  labels:
    {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          {{- if .Values.networkPolicies.istioNamespaceSelector }}
          kubernetes.io/metadata.name: {{ .Values.networkPolicies.istioNamespaceSelector.egress }}
          {{- else }}
          kubernetes.io/metadata.name: "istio-controlplane"
          {{- end }}
      podSelector:
        matchLabels:
          app.kubernetes.io/name: istiod
    ports:
    - port: 15012
      protocol: TCP
    - port: 15014
      protocol: TCP
{{- if and .Values.monitoring .Values.monitoring.enabled }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prometheus-ingress
  namespace: "{{ .Release.Namespace }}"
  labels:
    {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
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
  {{- if and .Values.redis .Values.redis.enabled }}
    - port: 9121
      protocol: TCP
  {{- end }}
{{- end }}
{{- end }}
{{- if and .Values.tracing .Values.tracing.enabled }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-tempo-egress
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: tempo
      podSelector:
        matchLabels:
          app.kubernetes.io/name: tempo
    ports:
    - port: 9411
{{- end }}
{{- end }}
{{- end }}