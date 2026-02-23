{{- define "bb-common.istio.authorization-policies.defaults.allow-nothing" }}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: {{ include "bb-common.prepend-release-name" (list . "default-authz-allow-nothing" "istio") | trim }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.network-policies.default-labels" "authorization-policy" | nindent 4 }}
spec: {}
{{- end }}