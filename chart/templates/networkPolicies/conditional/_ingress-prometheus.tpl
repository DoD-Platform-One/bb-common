{{- define "bb-common.netpols.ingress-prometheus" }}
{{- $minioTenant := index .Values "minio-tenant" }}
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