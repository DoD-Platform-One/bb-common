{{- define "bb-common.istio.authorization-policies.generate.from-k8s-network-policy" }} 
  {{- $ctx := index . 0 }}
  {{- $netpol := index . 1 }}
  {{- $ruleKey := index . 2 }}
  {{- $ruleValue := index . 3 }}
  {{- $name := index . 4 }}
  {{- $labels := index . 5 }}
  {{- $annotations := index . 6 }}
  {{- $local := index . 7 }}
  
  {{- $remote := include "bb-common.network-policies.ingress.parse.k8s-remote-key" $ruleKey | fromYaml }}

  {{- $authzPolicy := dict }}
  {{- $_ := set $authzPolicy "apiVersion" "security.istio.io/v1" }}
  {{- $_ := set $authzPolicy "kind" "AuthorizationPolicy" }}

  {{- if $remote.identity }}
    {{- /* Use the NetworkPolicy name and just append the identity */}}
    {{- $name = printf "%s-with-identity-%s" $netpol.metadata.name $remote.identity }}
    {{- $_ := set $annotations "generated.authorization-policies.bigbang.dev/from-spiffe" $ruleKey }}
    {{- $_ := set $annotations "generated.authorization-policies.bigbang.dev/identity" $remote.identity }}
  {{- else }}
    {{- /* Use the NetworkPolicy name and append namespace */}}
    {{- $name = printf "%s-from-ns-%s" $netpol.metadata.name $remote.namespace }}
    {{- $_ := set $annotations "generated.authorization-policies.bigbang.dev/from-namespace" $ruleKey }}
    {{- if $remote.pod }}
      {{- $_ := set $annotations "generated.authorization-policies.bigbang.dev/pod" $remote.pod }}
    {{- end }}
  {{- end }}

  {{- $metadata := dict "name" $name "labels" $labels "annotations" $annotations "namespace" $ctx.Release.Namespace }}
  {{- $_ := set $authzPolicy "metadata" $metadata }}

  {{- $spec := dict }}

  {{- $_ := set $spec "selector" $netpol.spec.podSelector }}

  {{- $rules := list }}
  {{- $rule := dict }}

  {{- if $remote.identity }}
    {{- $principals := list }}
    {{- $spiffeId := printf "cluster.local/ns/%s/sa/%s" $remote.namespace $remote.identity }}
    {{- $principals = append $principals $spiffeId }}
    {{- $_ := set $rule "from" (list (dict "source" (dict "principals" $principals))) }}
  {{- else }}
    {{- $namespaces := list }}
    {{- $namespaces = append $namespaces $remote.namespace }}
    {{- $_ := set $rule "from" (list (dict "source" (dict "namespaces" $namespaces))) }}
  {{- end }}

  {{- if $netpol.spec.ingress }}
    {{- $firstRule := index $netpol.spec.ingress 0 }}
    {{- if $firstRule.ports }}
      {{- $toRules := list }}
      {{- range $port := $firstRule.ports }}
        {{- $operation := dict }}
        {{- if $port.endPort }}
          {{- /* AuthorizationPolicy doesn't support port ranges, so we need to expand them */}}
          {{- $portList := list }}
          {{- $startPort := $port.port | int }}
          {{- $endPort := $port.endPort | int }}
          {{- range $p := (seq $startPort $endPort | split " ") }}
            {{- $portList = append $portList $p }}
          {{- end }}
          {{- $_ := set $operation "ports" ($portList | toStrings) }}
        {{- else }}
          {{- $_ := set $operation "ports" (list ($port.port | toString)) }}
        {{- end }}
        {{- $toRules = append $toRules (dict "operation" $operation) }}
      {{- end }}
      {{- $_ := set $rule "to" $toRules }}
    {{- end }}
  {{- end }}

  {{- $rules = append $rules $rule }}
  {{- $_ := set $spec "rules" $rules }}
  {{- $_ := set $spec "action" "ALLOW" }}

  {{- $_ := set $authzPolicy "spec" $spec }}
  
  {{- $authzPolicy | toYaml }}
{{- end }}
