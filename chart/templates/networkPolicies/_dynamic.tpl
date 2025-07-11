{{- define "bb-common.netpols.dynamic" }}
{{- if .Values.networkPolicies.bundled.kubeApiAccess.enabled }}
{{- range (.Values.networkPolicies.bundled.kubeApiAccess.pods | default (list nil)) }}
---
{{- include "bb-common.netpols.egress-kube-api" (dict "root" $ "pod" .) }}
{{- end }}
{{- end }}
{{- if .Values.networkPolicies.bundled.dynamic.enabled }}
{{- if and .Values.istio .Values.istio.enabled .Values.networkPolicies.bundled.dynamic.ingressGatewayPorts }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-istio-gateway-ingress
  namespace: "{{ .Release.Namespace }}"
  labels:
    {{- include "bb-common.label" .  | indent 4}}
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            {{- if .Values.networkPolicies.istioNamespaceSelector }}
            kubernetes.io/metadata.name: {{ .Values.networkPolicies.istioNamespaceSelector.ingress }}
            {{- else }}
            app.kubernetes.io/name: "istio-controlplane"
            {{- end }}
        podSelector:
          matchLabels:
            {{- toYaml .Values.networkPolicies.ingressLabels | nindent 12}}
      ports:
      {{- range .Values.networkPolicies.bundled.dynamic.ingressGatewayPorts }}
        - port: {{ .port }}
          {{- if .protocol }}
          protocol: {{ .protocol }}
          {{- end }}
      {{- end }}
{{- end }}
{{- if or (and .Values.sso .Values.sso.enabled) (and .Values.authservice .Values.authservice.enabled) }}
---
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
{{- if and .Values.monitoring .Values.monitoring.enabled .Values.networkPolicies.bundled.dynamic.metricsPorts }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring-metrics-ingress
  namespace: {{ .Release.Namespace }}
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: monitoring
        podSelector:
          matchLabels:
            app.kubernetes.io/name: prometheus
      ports:
      {{- range .Values.networkPolicies.bundled.dynamic.metricsPorts }}
        - port: {{ .port }}
          {{- if .protocol }}
          protocol: {{ .protocol }}
          {{- end }}
      {{- end }}
{{- end }}
{{- if and .Values.networkPolicies.bundled.dynamic.databaseCidrs (eq .Values.postgresql.enabled true) }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-postgresql-egress
  namespace: {{ .Release.Namespace }}
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - ports:
    - protocol: TCP
      port: 5432
    to:
  {{- range .Values.networkPolicies.bundled.dynamic.databaseCidrs }}
    - ipBlock:
        cidr: {{ . }}
        {{- include "bb-common.metadataExclude" . | indent 8 }}
  {{- end -}}
{{- end }}
{{- end }}
{{- end }}