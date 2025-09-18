{{- define "bb-common.routes.authz" }}
  {{- $ctx := index . 0 }}
  {{- $name := index . 1 }}
  {{- $route := index . 2 }}

  {{- $gatewayParts := split "/" (index $route.gateways 0) }}
  {{- $istioNamespace := $gatewayParts._0 }}
  {{- $istioGateway := $gatewayParts._1 }}

  {{- /* Build AuthorizationPolicy resource */}}
  {{- $authz := dict }}
  {{- $_ := set $authz "apiVersion" "security.istio.io/v1beta1" }}
  {{- $_ := set $authz "kind" "AuthorizationPolicy" }}

  {{- $metadata := dict "name" (printf "%s-%s-authz-policy" $name $istioGateway) "namespace" $ctx.Release.Namespace }}
  {{- if $route.metadata }}
    {{- if $route.metadata.labels }}
      {{- $_ := set $metadata "labels" $route.metadata.labels }}
    {{- end }}
    {{- if $route.metadata.annotations }}
      {{- $_ := set $metadata "annotations" $route.metadata.annotations }}
    {{- end }}
  {{- end }}
  {{- $_ := set $authz "metadata" $metadata }}

  {{- $spec := dict }}
  {{- $_ := set $spec "selector" (dict "matchLabels" $route.selector) }}
  {{- $_ := set $spec "action" "ALLOW" }}

  {{- $rule := dict }}
  {{- $source := dict "namespaces" (list $istioNamespace) "principals" (list (printf "cluster.local/ns/%s/sa/%s-ingressgateway-service-account" $istioNamespace $istioGateway)) }}
  {{- $_ := set $rule "from" (list (dict "source" $source)) }}
  {{- $_ := set $spec "rules" (list $rule) }}

  {{- $_ := set $authz "spec" $spec }}
  {{- $authz | toYaml }}
{{- end }}
