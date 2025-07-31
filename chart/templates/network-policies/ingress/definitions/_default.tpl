{{- define "bb-common.network-policies.ingress.definitions.default" }}
{{- /* NOTE: If you add/modify any definitions here, make sure you update the network-policies/README.md doc */}}
gateway:
  from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: istio-gateway
      podSelector:
        matchLabels:
          istio: ingressgateway
monitoring:
  from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
      podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
{{- end }}
