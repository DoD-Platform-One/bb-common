{{- define "bb-common.netpols.package" }}
{{- if .Values.networkPolicies.package }}
{{- range $name, $policy := .Values.networkPolicies.package }}
{{- if $policy.enabled }}
{{- $name = tpl $name $ }}
{{- $policy =  tpl (toYaml $policy) $ | fromYaml }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ $name }}
  namespace: "{{ $.Release.Namespace }}"
  labels:
    {{- include "bb-common.label" .  | indent 4}}
spec:
{{- if $policy.spec }}
  {{- tpl ($policy.spec | toYaml) $ | nindent 2 }}
{{- else }}
  {{- $podSelector := ternary $policy.from $policy.to (eq $policy.direction "Egress") }}
  {{- $podNamespaceSelector := ternary $policy.to $policy.from (eq $policy.direction "Egress") }}
  {{- if $podSelector }}
  {{- $podTarget := include "bb-common.splitPodAndNamespace" $podSelector | fromYaml }}
  {{- $pod := $podTarget.pod }}
  podSelector:
    matchLabels:
      app.kubernetes.io/name: {{ $pod }}
  {{- else }}
  podSelector: {}
  {{- end }}
  policyTypes:
    - {{ $policy.direction }}
  {{- if eq $policy.direction "Egress"}}
  egress:
    - to:
  {{- else }}
  ingress:
    - from:
  {{- end }}
  {{- $podNamespaceTarget := include "bb-common.splitPodAndNamespace" $podNamespaceSelector | fromYaml }}
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: {{ $podNamespaceTarget.namespace }}
        podSelector:
          matchLabels:
            app.kubernetes.io/name: {{ $podNamespaceTarget.pod }}
      {{- range $policy.ports }}
      ports:
        - port: {{ .port }}
        {{- if .protocol }}
          protocol: {{ .protocol }}
        {{- end }}
      {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
