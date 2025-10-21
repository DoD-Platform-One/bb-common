# Authorization Policies

BB-Common provides a framework for generating Istio AuthorizationPolicies alongside NetworkPolicies to secure service-to-service communication in your mesh.

## Overview

The authorization policies feature allows you to:

- Generate AuthorizationPolicies automatically from NetworkPolicy configurations
- Define custom AuthorizationPolicies using a simple YAML configuration
- Maintain consistent security policies across both network and service mesh layers

When enabled, BB-Common creates [default authorization policies](#default-authorization-policies) (allow-nothing and allow-intra-namespace) that work alongside any policies you generate or define.

## Generating AuthorizationPolicies from NetworkPolicies

### Enabling AuthorizationPolicy Generation

AuthorizationPolicies are automatically generated from NetworkPolicy configurations when:

1. `istio.authorizationPolicies.generateFromNetpol` is set to `true`
2. You define ingress NetworkPolicy rules with supported remote types (`k8s` or `cidr`)

```yaml
istio:
  authorizationPolicies:
    enabled: true
    generateFromNetpol: true # Enable AuthorizationPolicy generation
networkPolicies:
  enabled: true
  ingress:
    to:
      # Kubernetes rule without identity - uses namespace restrictions
      api:
        from:
          k8s:
            backend/worker: true

      # Kubernetes rule with identity - uses SPIFFE principals
      secure-api:
        from:
          k8s:
            api-sa@backend/worker: true

      # CIDR rule - uses IP address filtering
      public-api:8080:
        from:
          cidr:
            192.168.1.0/24: true
```

All three rule types generate both NetworkPolicies and AuthorizationPolicies. Custom policies defined in `additionalPolicies` work alongside these automatically generated policies.

### How AuthorizationPolicy Generation Works

When `generateFromNetpol` is enabled, the framework automatically creates corresponding AuthorizationPolicies for supported NetworkPolicy rule types:

#### For Kubernetes Rules with Service Account Identity

When you specify an identity prefix (e.g., `api-sa@`), the framework:

1. Generates a standard NetworkPolicy for L3/L4 network isolation
2. Generates an Istio AuthorizationPolicy that enforces SPIFFE identity verification

The AuthorizationPolicy uses the SPIFFE ID format:
`cluster.local/ns/<namespace>/sa/<service-account>`

**Example:**

```yaml
istio:
  authorizationPolicies:
    generateFromNetpol: true
networkPolicies:
  ingress:
    to:
      database:
        from:
          # Only "app" pods with "app-sa" service account in "backend" namespace can access
          k8s:
            app-sa@backend/app: true
```

Generates both:

1. NetworkPolicy: `allow-ingress-to-database-any-port-from-ns-backend-pod-app`
2. AuthorizationPolicy:
   `allow-ingress-to-database-any-port-from-ns-backend-pod-app-with-identity-app-sa`
   - Enforces SPIFFE identity: `cluster.local/ns/backend/sa/app-sa`

#### For Kubernetes Rules without Identity

When no service account identity is specified, both NetworkPolicy and AuthorizationPolicy are created. The AuthorizationPolicy uses namespace-based restrictions instead of SPIFFE identity:

```yaml
istio:
  authorizationPolicies:
    generateFromNetpol: true
networkPolicies:
  ingress:
    to:
      api:
        from:
          k8s:
            backend/worker: true  # Creates both NetworkPolicy and AuthorizationPolicy
```

Generates both:

1. NetworkPolicy: `allow-ingress-to-api-any-port-from-ns-backend-pod-worker`
2. AuthorizationPolicy: `allow-ingress-to-api-any-port-from-ns-backend-pod-worker-from-ns-backend`
   - Allows traffic from namespace: `backend`

#### For CIDR Rules

When CIDR-based rules are specified, both NetworkPolicy and AuthorizationPolicy are created:

```yaml
istio:
  authorizationPolicies:
    generateFromNetpol: true
networkPolicies:
  ingress:
    to:
      api:8080:
        from:
          cidr:
            192.168.1.0/24: true
```

Generates both:

1. NetworkPolicy: `allow-ingress-to-api-tcp-port-8080-from-cidr-192-168-1-0-24`
2. AuthorizationPolicy: `allow-ingress-to-api-tcp-port-8080-from-cidr-192-168-1-0-24`
   - Uses `ipBlocks` to restrict access to the specified CIDR range

### Important Notes

1. **Service Account Must Exist**: The specified service account (e.g., `api-sa`) must exist in the source namespace (for k8s-based rules with identity)
2. **Istio Required**: AuthorizationPolicies require Istio to be installed and both local and remote pods be part of the mesh
3. **mTLS Enabled**: Istio must be configured with mTLS for SPIFFE identity verification to work (for k8s-based rules with identity)
4. **CIDR Rules Use ipBlocks**: CIDR-based AuthorizationPolicies use `ipBlocks` which work with the direct source IP address from the packet. This is appropriate for direct connections (e.g., from Kubelet or node IPs). If you need to work with X-Forwarded-For headers or PROXY protocol, you may need to use `remoteIpBlocks` instead (requires custom AuthorizationPolicies)

## Configuration

### Basic Configuration

```yaml
istio:
  authorizationPolicies:
    # Enable/disable the generation of Istio AuthorizationPolicies
    enabled: true
```

### Default Authorization Policies

When enabled, BB-Common creates two default authorization policies:

#### 1. Deny All (`allow-nothing`)

A default-deny policy with an empty spec that blocks all traffic unless explicitly allowed.

**Policy Name**: `{{ .Release.Name }}-allow-nothing`

#### 2. Allow Intra-Namespace (`default-authz-allow-all-in-ns`)

Allows traffic between workloads within the same namespace.

**Policy Name**: `{{ .Release.Name }}-default-authz-allow-all-in-ns`

### Disabling Default Policies

```yaml
istio:
  authorizationPolicies:
    defaults:
      denyAll:
        enabled: false
      allowInNamespace:
        enabled: false
```

### Additional Policies

You can define custom AuthorizationPolicies that will be rendered alongside the automatically generated ones. The configuration uses a map structure to avoid override issues when using multiple values files.

**Note**: For last-mile configuration needs, you can also use `istio.hardened.customAuthorizationPolicies` which is documented in the [Istio Resources](../istio/README.md#custom-authorizationpolicies) documentation. While this duplicates the `additionalPolicies` functionality, it is maintained for backwards compatibility with existing configurations.

```yaml
istio:
  authorizationPolicies:
    enabled: true
    additionalPolicies:
      my-custom-policy:
        enabled: true
        # Optional: override the policy name (defaults to map key)
        # name: custom-policy-name
        # Optional metadata
        labels:
          app: my-app
          environment: production
        annotations:
          description: "Custom authorization policy for my application"
        # Istio AuthorizationPolicy spec
        spec:
          selector:
            matchLabels:
              app: my-app
          rules:
            - from:
              - source:
                  principals: ["cluster.local/ns/default/sa/my-service-account"]
      another-policy:
        enabled: true
        spec:
          selector:
            matchLabels:
              app: another-app
          action: DENY
          rules:
            - to:
              - operation:
                  paths: ["/admin/*"]
```

### Configuration Options

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `enabled` | boolean | Enable/disable authorization policy generation | `true` |
| `additionalPolicies` | object | Map of custom authorization policies | `{}` |
| `additionalPolicies.<key>` | object | Policy configuration (key becomes policy name) | - |
| `additionalPolicies.<key>.name` | string | Override policy name (defaults to map key) | `<key>` |
| `additionalPolicies.<key>.enabled` | boolean | Enable/disable this specific policy | `true` |
| `additionalPolicies.<key>.labels` | object | Additional labels for the policy | `{}` |
| `additionalPolicies.<key>.annotations` | object | Additional annotations for the policy | `{}` |
| `additionalPolicies.<key>.spec` | object | Istio AuthorizationPolicy specification | - |

## Examples

### Allow Traffic from Specific Service Account

```yaml
istio:
  authorizationPolicies:
    additionalPolicies:
      allow-api-access:
        enabled: true
        spec:
          selector:
            matchLabels:
              app: backend-api
          rules:
            - from:
              - source:
                  principals: ["cluster.local/ns/frontend/sa/web-service"]
              to:
              - operation:
                  methods: ["GET", "POST"]
                  paths: ["/api/v1/*"]
```

## References

- [Istio Authorization Policy Documentation](https://istio.io/latest/docs/reference/config/security/authorization-policy/)
- [BB-Common Network Policies](../network-policies/README.md)