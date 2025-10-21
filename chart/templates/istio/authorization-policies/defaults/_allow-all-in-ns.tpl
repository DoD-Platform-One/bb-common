{{- define "bb-common.istio.authorization-policies.defaults.allow-all-in-ns" }}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: {{ include "bb-common.network-policies.prepend-release-name" (list . "default-authz-allow-all-in-ns") }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.network-policies.default-labels" "authorization-policy" | nindent 4 }}
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["{{ .Release.Namespace }}"]
{{- end }}