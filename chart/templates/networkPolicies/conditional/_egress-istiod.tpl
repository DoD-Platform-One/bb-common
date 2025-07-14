{{- define "bb-common.netpols.egress-istiod" }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-istiod-egress
  namespace: "{{ .Release.Namespace }}"
  labels:
    {{- include "bb-common.label" . | indent 4 }}
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          {{- if .Values.networkPolicies.istioNamespaceSelector }}
          kubernetes.io/metadata.name: {{ .Values.networkPolicies.istioNamespaceSelector.egress }}
          {{- else }}
          kubernetes.io/metadata.name: "istio-controlplane"
          {{- end }}
      podSelector:
        matchLabels:
          app.kubernetes.io/name: istiod
    ports:
    - port: 15012
      protocol: TCP
    - port: 15014
      protocol: TCP
{{- end }}