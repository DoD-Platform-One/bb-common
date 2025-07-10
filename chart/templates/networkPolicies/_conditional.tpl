{{- define "bb-common.netpols.conditional" }}
{{- $minioTenant := index .Values "minio-tenant" }}
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
  {{- if or (and .Values.minio (or .Values.minio.enabled .Values.minio.install)) (and $minioTenant $minioTenant.enabled) }}
    - port: 9000
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
{{- if or (and .Values.minio (or .Values.minio.enabled .Values.minio.install)) (and $minioTenant $minioTenant.enabled) }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-minio-operator
  namespace: {{ .Release.Namespace }}
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: minio
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: minio-operator
        podSelector:
          matchLabels:
            app.kubernetes.io/name: minio-operator
      ports:
      - port: 9000
        protocol: TCP
  egress:
    - to:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: minio-operator
        podSelector:
          matchLabels:
            app.kubernetes.io/name: minio-operator
      ports:
      - port: 4222
        protocol: TCP
{{- end }}
{{- end }}
{{- end }}