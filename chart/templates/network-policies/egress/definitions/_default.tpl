{{- define "bb-common.network-policies.egress.definitions.default" }}
{{- /* NOTE: If you add/modify any definitions here, make sure you update the network-policies/README.md doc */}}
kubeAPI:
  to:
    - ipBlock:
        cidr: 10.0.0.0/8
    - ipBlock:
        cidr: 172.16.0.0/12
    - ipBlock:
        cidr: 192.168.0.0/16
  {{- $apiService := lookup "v1" "Service" "default" "kubernetes" }}
  {{- if and $apiService $apiService.spec.ports }}
  ports:
    {{- range $port := $apiService.spec.ports }}
    - port: {{ $port.targetPort }}
      protocol: "TCP"
    {{- end }}
  {{- end }}
{{- end }}

