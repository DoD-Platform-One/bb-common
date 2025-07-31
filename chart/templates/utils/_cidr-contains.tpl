{{- /*
  Checks if cidrA contains cidrB.
*/}}
{{- define "bb-common.utils.cidr-contains" }}
  {{- $cidrA := index . 0 -}}
  {{- $cidrB := index . 1 -}}

  {{- $partsA := splitList "/" $cidrA -}}
  {{- $ipA := index $partsA 0 -}}
  {{- $maskA := index $partsA 1 | int -}}

  {{- $partsB := splitList "/" $cidrB -}}
  {{- $ipB := index $partsB 0 -}}
  {{- $maskB := index $partsB 1 | int -}}

  {{- if lt $maskB $maskA -}}
    {{ false | toYaml }}
  {{- else -}}

  {{- $octetsA := splitList "." $ipA -}}
  {{- $octetsB := splitList "." $ipB -}}

  {{- $ipIntA := 0 -}}
  {{- $ipIntA = add $ipIntA (mul (index $octetsA 0 | int) 16777216) -}}
  {{- $ipIntA = add $ipIntA (mul (index $octetsA 1 | int) 65536) -}}
  {{- $ipIntA = add $ipIntA (mul (index $octetsA 2 | int) 256) -}}
  {{- $ipIntA = add $ipIntA (index $octetsA 3 | int) -}}

  {{- $ipIntB := 0 -}}
  {{- $ipIntB = add $ipIntB (mul (index $octetsB 0 | int) 16777216) -}}
  {{- $ipIntB = add $ipIntB (mul (index $octetsB 1 | int) 65536) -}}
  {{- $ipIntB = add $ipIntB (mul (index $octetsB 2 | int) 256) -}}
  {{- $ipIntB = add $ipIntB (index $octetsB 3 | int) -}}

  {{- $shiftBits := sub 32 $maskA -}}
  {{- $divisor := 1 -}}
  {{- range $i := until ($shiftBits | int) -}}
    {{- $divisor = mul $divisor 2 -}}
  {{- end -}}

  {{- $networkA := div $ipIntA $divisor -}}
  {{- $networkB := div $ipIntB $divisor -}}

  {{- eq $networkA $networkB | toYaml -}}

  {{- end -}}
{{- end }}
