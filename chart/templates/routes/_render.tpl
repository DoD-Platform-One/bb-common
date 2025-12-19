{{- define "bb-common.routes.render" }}
  {{- include "bb-common.routes.inbound.render" . }}
  {{- include "bb-common.routes.outbound.render" . }}
{{- end }}
