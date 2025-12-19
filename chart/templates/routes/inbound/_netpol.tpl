{{- define "bb-common.routes.inbound.netpol" }}
  {{- $ctx := index . 0 }}
  {{- $name := index . 1 }}
  {{- $route := index . 2 }}

  {{- $gatewayParts := split "/" (index $route.gateways 0) }}
  {{- $istioNamespace := $gatewayParts._0 }}
  {{- $istioGateway := $gatewayParts._1 }}

  {{- /* Build NetworkPolicy resource */}}
  {{- $netpol := dict }}
  {{- $_ := set $netpol "apiVersion" "networking.k8s.io/v1" }}
  {{- $_ := set $netpol "kind" "NetworkPolicy" }}


  {{- $portSuffix := "any-port" }}
  {{- if $route.port }}
    {{- $portSuffix = toString $route.port }}
  {{- end }}
  {{- $metadata := dict "name" (printf "allow-ingress-to-%s-%s-from-ns-%s-pod-%s" $name $portSuffix $istioNamespace $istioGateway) "namespace" $ctx.Release.Namespace }}
  {{- if $route.metadata }}
    {{- if $route.metadata.labels }}
      {{- $_ := set $metadata "labels" $route.metadata.labels }}
    {{- end }}
    {{- if $route.metadata.annotations }}
      {{- $_ := set $metadata "annotations" $route.metadata.annotations }}
    {{- end }}
  {{- end }}
  {{- $_ := set $netpol "metadata" $metadata }}

  {{- $spec := dict }}
  {{- $_ := set $spec "podSelector" (dict "matchLabels" $route.selector) }}
  {{- $_ := set $spec "policyTypes" (list "Ingress") }}

  {{- $ingress := dict }}
  {{- $namespaceSelector := dict "matchLabels" (dict "kubernetes.io/metadata.name" $istioNamespace) }}
  {{- $podSelector := dict "matchLabels" (dict "app.kubernetes.io/name" $istioGateway "istio" "ingressgateway") }}
  {{- $from := dict "namespaceSelector" $namespaceSelector "podSelector" $podSelector }}
  {{- $_ := set $ingress "from" (list $from) }}
  {{- if $route.port }}
    {{- $_ := set $ingress "ports" (list (dict "port" $route.port)) }}
  {{- end }}
  {{- $_ := set $spec "ingress" (list $ingress) }}

  {{- $_ := set $netpol "spec" $spec }}

  {{- if dig "hbonePortInjection" "enabled" true $ctx.Values.networkPolicies }}
    {{- $_ := include "bb-common.network-policies.inject-hbone-ports" (list (list $netpol) "ingress") | fromYaml }}
  {{- end }}

  {{- $netpol | toYaml }}
{{- end }}
