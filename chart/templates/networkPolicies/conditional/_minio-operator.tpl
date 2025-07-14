{{- define "bb-common.netpols.minio-operator" }}
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