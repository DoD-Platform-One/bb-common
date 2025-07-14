{{- define "bb-common.netpols.egress-postgresql" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-postgresql-egress
  namespace: {{ .Release.Namespace }}
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - ports:
    - protocol: TCP
      port: 5432
    to:
  {{- range .Values.networkPolicies.bundled.dynamic.databaseCidrs }}
    - ipBlock:
        cidr: {{ . }}
        {{- include "bb-common.metadataExclude" . | indent 8 }}
  {{- end -}}
{{- end }}