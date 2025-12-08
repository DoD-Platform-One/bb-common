{{- define "bb-common.istio.authorization-policies.defaults.allow-nothing" }}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: {{ include "bb-common.network-policies.prepend-release-name" (list . "default-authz-allow-nothing") }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bb-common.network-policies.default-labels" "authorization-policy" | nindent 4 }}
spec: {}
{{- end }}