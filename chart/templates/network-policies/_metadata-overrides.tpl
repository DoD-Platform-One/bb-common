{{- define "bb-common.network-policies.metadata-overrides" }}
  {{- $localValue := index . 0 }}
  {{- $remoteValue := index . 1 }}

  {{- $metadata := dict }}

  {{- $localMetadata := dig "metadata" dict $localValue }}
  {{- $localAnnotations := dig "annotations" dict $localMetadata }}
  {{- $localLabels := dig "labels" dict $localMetadata }}

  {{- $remoteAnnotations := dict }}
  {{- $remoteLabels := dict }}

  {{- if kindIs "map" $remoteValue }}
    {{- $remoteMetadata := dig "metadata" dict $remoteValue }}
    {{- $remoteAnnotations = dig "annotations" dict $remoteMetadata }}
    {{- $remoteLabels = dig "labels" dict $remoteMetadata }}
  {{- end }}

  {{- $mergedAnnotations := merge $remoteAnnotations $localAnnotations }}
  {{- $mergedLabels := merge $remoteLabels $localLabels }}
  {{- $metadata = merge $metadata (dict "annotations" $mergedAnnotations "labels" $mergedLabels) }}

  {{- (dict "metadata" $metadata) | toYaml }}
{{- end }}
