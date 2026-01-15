{{- define "bb-common.utils.dedupe" }}
  {{- $resources := . }}
  {{- if not (kindIs "slice" $resources) }}
    {{- $resources = list }}{{/* not a list; nothing to dedupe */}}
  {{- end }}

  {{- $seen := dict }}
  {{- $duplicates := dict }}
  {{- $skipIndices := list }}

  {{- range $i, $resource := $resources }}
    {{- if not (kindIs "map" $resource) }}
      {{- continue }}{{/* not a valid k8s resource; skip it */}}
    {{- end }}

    {{- $kind := dig "kind" "" $resource }}
    {{- $name := dig "metadata" "name" "" $resource }}

    {{- if or (empty $kind) (empty $name) }}
      {{- continue }}{{/* not a valid k8s resource; skip it */}}
    {{- end }}

    {{- $key := printf "%s/%s" $kind $name }}
    {{- $hash := omit $resource "metadata" "status" | toJson | sha256sum }}

    {{- $existing := index $seen $key }}
    {{- if empty $existing }}
      {{- $_ := set $seen $key (dict 
        "hash" $hash 
        "firstIndex" $i 
        "seenHashes" (dict $hash true)
      )}}

      {{- continue }}
    {{- end }}

    {{- if hasKey $existing.seenHashes $hash }}
      {{- $skipIndices = append $skipIndices $i }}
      {{- continue }}
    {{- end }}

    {{- $_ := set $existing.seenHashes $hash true }}

    {{- if not (hasKey $duplicates $key) }}
      {{- $_ := set $duplicates $key (list $existing.firstIndex) }}
    {{- end }}

    {{- $_ := set $duplicates $key (append (index $duplicates $key) $i) }}
  {{- end }}

  {{- $deduped := $resources | toYaml | fromYamlArray }}

  {{- range $key, $indices := $duplicates }}
    {{- range $i, $index := $indices }}
      {{- $duplicate := index $deduped $index }}
      {{- $duplicate = mergeOverwrite $duplicate (dict 
        "metadata" (dict 
          "name" (printf "%s-deduped-%d" $duplicate.metadata.name $i)
          "annotations" (dict
            "generated.bigbang.dev/deduplicated" "true"
          )
        )
      )}}
    {{- end }}
  {{- end }}

  {{- range $i, $skipIndex := $skipIndices }}
    {{- $skipIndex = sub $skipIndex $i }}{{/* adjust index due to prior removals */}}

    {{- if eq $skipIndex (len $deduped) }}
      {{- $deduped = slice $deduped 0 $skipIndex }}
      {{- continue }}
    {{- end }}

    {{- $deduped = concat (slice $deduped 0 $skipIndex) (slice $deduped (add $skipIndex 1)) }}
  {{- end }}

  {{- $deduped | toYaml }}
{{- end }}
