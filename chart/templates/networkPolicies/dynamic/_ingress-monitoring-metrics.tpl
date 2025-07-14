{{- define "bb-common.netpols.ingress-monitoring-metrics" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring-metrics-ingress
  namespace: {{ .Release.Namespace }}
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
      {{- range .Values.networkPolicies.bundled.dynamic.metricsPorts }}
        - port: {{ .port }}
          {{- if .protocol }}
          protocol: {{ .protocol }}
          {{- end }}
      {{- end }}
{{- end }}