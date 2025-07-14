{{- define "bb-common.netpols.ingress-istio-gateway" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-istio-gateway-ingress-{{ .name }}
  namespace: "{{ .root.Release.Namespace }}"
  labels:
    {{- include "bb-common.label" .root  | indent 4}}
spec:
  podSelector:
    {{- if hasKey .item "selector" }}
    {{- if .item.selector }}
    matchLabels:
      {{- toYaml .item.selector | nindent 6}}
    {{- else }}
    {}
    {{- end }}
    {{- else }}
    matchLabels:
      app.kubernetes.io/name: {{ .name }}
    {{- end }}
  policyTypes:
    - Ingress
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            {{- if .root.Values.networkPolicies.istioNamespaceSelector }}
            kubernetes.io/metadata.name: {{ .root.Values.networkPolicies.istioNamespaceSelector.ingress }}
            {{- else }}
            app.kubernetes.io/name: "istio-controlplane"
            {{- end }}
        podSelector:
          matchLabels:
            {{- toYaml .root.Values.networkPolicies.ingressLabels | nindent 12}}
      ports:
      {{- range .item.ports }}
        - port: {{ .port }}
          {{- if .protocol }}
          protocol: {{ .protocol }}
          {{- end }}
      {{- end }}
{{- end }}
