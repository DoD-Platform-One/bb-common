{{- define "bb-common.netpols.egress-sso" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-sso-egress
  namespace: "{{ .Release.Namespace }}"
  labels:
    {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
  {{- if .Values.networkPolicies.bundled.dynamic.ssoCidrs }}
  {{- range .Values.networkPolicies.bundled.dynamic.ssoCidrs }}
    - ipBlock:
        cidr: {{ . }}
        {{- include "bb-common.metadataExclude" . | indent 8 }}
  {{- end -}}
  {{- else }}
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32
  {{- end }}
{{- end }}