# Network Policies Documentation

The bb-common Helm chart provides a comprehensive network policy framework that
simplifies the creation and management of Kubernetes NetworkPolicies. This
feature enables fine-grained control over network traffic between pods,
namespaces, and external resources.

## Table of Contents

<!--toc:start-->

- [Network Policies Documentation](#network-policies-documentation)
  - [Table of Contents](#table-of-contents)
  - [Quick Start](#quick-start)
  - [Overview](#overview)
  - [Configuration Syntax](#configuration-syntax)
    - [Kubernetes Rules (`k8s`)](#kubernetes-rules-k8s)
    - [CIDR Rules (`cidr`)](#cidr-rules-cidr)
    - [Definition Rules (`definition`)](#definition-rules-definition)
    - [Literal Rules (`literal`)](#literal-rules-literal)
    - [Port Specifications](#port-specifications)
  - [How It Works](#how-it-works)
    - [Selector Behavior](#selector-behavior)
    - [Shorthand to NetworkPolicy Translation](#shorthand-to-networkpolicy-translation)
      - [Example 1: Basic Egress Rule](#example-1-basic-egress-rule)
      - [Example 2: Ingress Rule with Port on Local Pod](#example-2-ingress-rule-with-port-on-local-pod)
  - [Configuration](#configuration)
    - [Enabling Network Policies](#enabling-network-policies)
    - [Basic Egress Rules](#basic-egress-rules)
    - [Basic Ingress Rules](#basic-ingress-rules)
    - [Default Policies](#default-policies)
      - [Egress Defaults](#egress-defaults)
      - [Ingress Defaults](#ingress-defaults)
  - [Built-in Definitions](#built-in-definitions)
    - [Egress Definitions](#egress-definitions)
    - [Ingress Definitions](#ingress-definitions)
    - [Overriding the Default Definitions](#overriding-the-default-definitions)
  - [Examples](#examples)
    - [Basic Web Application](#basic-web-application)
    - [Microservices Architecture](#microservices-architecture)
    - [Multi-Namespace Setup](#multi-namespace-setup)
  - [Advanced Features](#advanced-features)
    - [Protocol Support](#protocol-support)
    - [Advanced Port Patterns](#advanced-port-patterns)
    - [Custom Pod Selectors](#custom-pod-selectors)
    - [Custom Definitions](#custom-definitions)
    - [Spec Literals](#spec-literals)
    - [Additional Policies](#additional-policies)
    - [SPIFFE-based AuthorizationPolicies](#spiffe-based-authorizationpolicies)
      - [Enabling AuthorizationPolicies](#enabling-authorizationpolicies)
      - [How AuthorizationPolicy Generation Works](#how-authorizationpolicy-generation-works)
      - [AuthorizationPolicy Examples](#authorizationpolicy-examples)
      - [Important Notes](#important-notes)
  - [Labels and Annotations](#labels-and-annotations)
  - [Migration Guide](#migration-guide)
    - [Using bb-common as a Subchart](#using-bb-common-as-a-subchart)
      - [Step 1: Add bb-common to Chart.yaml](#step-1-add-bb-common-to-chartyaml)
      - [Step 2: Configure Network Policies in values.yaml](#step-2-configure-network-policies-in-valuesyaml)
    - [Using bb-common as a Library Chart](#using-bb-common-as-a-library-chart)
      - [Step 1: Add bb-common as a library dependency](#step-1-add-bb-common-as-a-library-dependency)
      - [Step 2: Include the network policy templates](#step-2-include-the-network-policy-templates)
      - [Step 3: Configure Network Policies in values.yaml](#step-3-configure-network-policies-in-valuesyaml)
    - [Migration Examples](#migration-examples)
      - [Basic Pod-to-Pod Communication](#basic-pod-to-pod-communication)
      - [Multiple Pods and Ports](#multiple-pods-and-ports)
      - [Complex Ingress Rules](#complex-ingress-rules)
      - [Wildcard Namespace Selectors](#wildcard-namespace-selectors)
      - [CIDR Blocks with Exceptions](#cidr-blocks-with-exceptions)
        - [Overriding the excluded CIDRs](#overriding-the-excluded-cidrs)
      - [Nonstandard Pod Selectors](#nonstandard-pod-selectors)
      - [Match Expressions](#match-expressions)
      - [UDP and Mixed Protocols](#udp-and-mixed-protocols)
      - [Port Ranges](#port-ranges)
      - [Multiple Policy Types](#multiple-policy-types)
      - [Empty Selectors (Allow All)](#empty-selectors-allow-all)
      - [Combining with Default Policies](#combining-with-default-policies)
    - [Migration Strategy](#migration-strategy)
  - [Troubleshooting](#troubleshooting)

<!--toc:end-->

## Quick Start

To enable network policies and create a simple egress rule:

```yaml
networkPolicies:
  enabled: true
  egress:
    from:
      app:
        to:
          k8s:
            backend/api:8080: true # Include port for precise control
```

This creates a policy allowing pods labeled `app.kubernetes.io/name: app` to
connect to pods labeled `app.kubernetes.io/name: api` in the `backend` namespace
on port 8080.

> **Note about YAML syntax**: The keys like `backend/api:8080:` might look
> unusual, but they are perfectly valid YAML. The slash and colon are allowed in
> YAML keys when used as shown. This syntax enables our powerful shorthand
> notation while keeping your configuration concise and readable.

## Overview

The network policy feature in bb-common provides:

- **Declarative syntax** for defining network policies
- **Shorthand notations** for common patterns
- **Default policies** for common security requirements
- **Reusable definitions** for frequently used rules
- **Automatic policy naming** based on rules
- **Support for raw NetworkPolicy specs** when needed

## Configuration Syntax

The chart uses a structured YAML format with three main rule types:

### Kubernetes Rules (`k8s`)

Kubernetes rules allow traffic between pods and namespaces. The format for the
rule key is: `[<identity>@]<namespace>/<pod>:<port>`

Examples:

```yaml
networkPolicies:
  egress:
    from:
      my-app:
        to:
          k8s:
            backend/api:8080: true # Specific pod and port
            backend/api: true # Any port on api pod
            backend/*: true # Any pod in backend namespace
            backend/*:8080: true # Any pod on specific port
            "*/prometheus:9090": true # Prometheus in any namespace
            "*/*": true # Any pod in any namespace
```

For ingress rules with identity-based authorization (requires
`ingress.generateAuthorizationPolicies: true`):

```yaml
networkPolicies:
  ingress:
    generateAuthorizationPolicies: true
    to:
      api:
        from:
          k8s:
            frontend/web: true # NetworkPolicy only
            api-sa@backend/worker: true # NetworkPolicy + AuthorizationPolicy
```

### CIDR Rules (`cidr`)

CIDR rules allow traffic to/from IP address ranges. The format is:
`<ip-range>[:<port>]`

```yaml
networkPolicies:
  egress:
    from:
      my-app:
        to:
          cidr:
            10.0.0.0/8:443: true # Private network HTTPS
            192.168.1.0/24:22: true # SSH to local network
            0.0.0.0/0:443: true # Internet HTTPS (metadata endpoint auto-blocked by default)
            52.84.23.62/32:[80,443]: true # Multiple ports to specific IP
```

> **Note**: When using `0.0.0.0/0`, the commonly-used cloud metadata endpoint
> address `169.254.169.254/32` is automatically excluded.

### Definition Rules (`definition`)

Definitions are reusable rule sets. You can use built-in definitions or create
custom ones:

```yaml
networkPolicies:
  egress:
    from:
      my-app:
        to:
          definition:
            kubeAPI: true # Built-in: Kubernetes API access
            my-custom-api: true # Custom definition (outlined in a section below)

  ingress:
    to:
      my-app:
        from:
          definition:
            gateway: true # Built-in: Istio ingress gateway
            monitoring: true # Built-in: Prometheus
```

Built-in definitions are outlined [below](#built-in-definitions).

### Literal Rules (`literal`)

For complex scenarios, you can provide raw NetworkPolicy spec fragments:

```yaml
networkPolicies:
  egress:
    from:
      my-app:
        to:
          literal:
            complex-rule:
              enabled: true
              spec:
                - to:
                    - namespaceSelector:
                        matchExpressions:
                          - key: environment
                            operator: In
                            values: ["production", "staging"]
                  ports:
                    - port: 443
                      protocol: TCP
```

### Port Specifications

Ports are a critical part of network policies and should be specified whenever
possible for precise traffic control:

**For Egress (outbound)** - Port goes on the destination:

```yaml
backend/api:8080: true # Single port
backend/api:[80,443]: true # Multiple ports
backend/api:8080-8090: true # Port range
10.0.0.0/8:443: true # CIDR with port
```

**For Ingress (inbound)** - Port goes on the local pod:

```yaml
api: true # Local pod accepts all ports (not recommended)
api:8080: true # Local pod accepts on port 8080
api:[80,443]: true # Local pod accepts on multiple ports
web:8080-8090: true # Local pod accepts on port range
```

> **Important**: Always specify ports unless you explicitly need to allow all
> ports. This follows the principle of least privilege.

## How It Works

### Selector Behavior

The network policy framework uses specific label selectors for identifying pods
and namespaces:

- **Namespace Selectors**: Match on the actual namespace name using the
  `kubernetes.io/metadata.name` label
- **Pod Selectors**: Match on the `app.kubernetes.io/name` label by default

For example, the shorthand `backend/api` translates to:

- Namespace selector:
  `matchLabels: { "kubernetes.io/metadata.name": "backend" }`
- Pod selector: `matchLabels: { "app.kubernetes.io/name": "api" }`

### Shorthand to NetworkPolicy Translation

Here's how shorthand syntax translates into Kubernetes NetworkPolicy resources:

#### Example 1: Basic Egress Rule

```yaml
# Shorthand
networkPolicies:
  egress:
    from:
      frontend:
        to:
          k8s:
            backend/api:8080: true

# Generates this NetworkPolicy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-from-frontend-to-ns-backend-pod-api-tcp-port-8080
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: backend
          podSelector:
            matchLabels:
              app.kubernetes.io/name: api
      ports:
        - port: 8080
          protocol: TCP
```

#### Example 2: Ingress Rule with Port on Local Pod

```yaml
# Shorthand (note: port is on the local pod identifier)
networkPolicies:
  ingress:
    to:
      api:8080:
        from:
          k8s:
            frontend/web: true

# Generates this NetworkPolicy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-api-tcp-port-8080-from-ns-frontend-pod-web
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
          podSelector:
            matchLabels:
              app.kubernetes.io/name: web
      ports:
        - port: 8080
          protocol: TCP
```

> **Important**: For ingress rules, ports are specified on the local pod (the
> destination), not in the remote identifier. This is because ingress rules
> define which ports on the local pod accept traffic.

## Configuration

### Enabling Network Policies

Network policies are disabled by default. Enable them by setting:

```yaml
networkPolicies:
  enabled: true
```

### Basic Egress Rules

Egress rules control outbound traffic from pods. Always specify ports for
security:

```yaml
networkPolicies:
  egress:
    from:
      frontend: # Pods with label app.kubernetes.io/name: frontend
        to:
          k8s:
            backend/api:8080: true # API on specific port
            cache/redis:6379: true # Redis cache
          cidr:
            52.84.0.0/16:443: true # External HTTPS API
```

> **Port placement**: For egress rules, ports are specified on the destination
> (where traffic is going).

### Basic Ingress Rules

Ingress rules control inbound traffic to pods. Port specifications go on the
receiving pod:

```yaml
networkPolicies:
  ingress:
    to:
      api:8080: # API pod accepts traffic on port 8080
        from:
          k8s:
            frontend/web: true # From frontend web pods
            monitoring/prometheus: true # From Prometheus

      database:5432: # Database accepts on PostgreSQL port
        from:
          k8s:
            backend/api: true # Only from API pods
```

> **Port placement**: For ingress rules, ports are specified on the local pod
> (where traffic is received).

### Default Policies

The chart provides several default policies that implement common security
patterns. These are all **enabled by default** when you enable network policies.

#### Egress Defaults

```yaml
networkPolicies:
  egress:
    defaults:
      enabled: true # Enable all defaults (this is the default)
      # Or control individually:
      denyAll:
        enabled: true # Deny all egress by default
      allowInNamespace:
        enabled: true # Allow egress within the same namespace
      allowKubeDns:
        enabled: true # Allow DNS resolution (TCP/UDP port 53)
      allowIstiod:
        enabled: true # Allow Istio control plane communication (TCP port 15012)
```

#### Ingress Defaults

```yaml
networkPolicies:
  ingress:
    defaults:
      enabled: true # Enable all defaults (this is the default)
      # Or control individually:
      denyAll:
        enabled: true # Deny all ingress by default
      allowInNamespace:
        enabled: true # Allow ingress from same namespace
```

> **Important**: You only need to specify these in your values if you want to
> **disable** specific defaults. They are all enabled automatically.

## Built-in Definitions

The chart includes pre-configured definitions for common scenarios:

### Egress Definitions

- **kubeAPI**: Allow access to Kubernetes API server
  - Includes common private network ranges: 10.0.0.0/8, 172.16.0.0/12,
    192.168.0.0/16

### Ingress Definitions

- **gateway**: Allow traffic from Istio ingress gateway
  - Namespace: `istio-gateway`
  - Pod labels: `app: istio-ingressgateway`, `istio: ingressgateway`

- **monitoring**: Allow traffic from Prometheus
  - Namespace: `monitoring`
  - Pod labels: `app.kubernetes.io/name: prometheus`

### Overriding the Default Definitions

You can override these default definitions in your values if necessary. Note
that overriding a definition will replace that definition entirely. It **will
not be merged** with the existing default definition.

## Examples

### Basic Web Application

A simple web application with proper port specifications:

```yaml
networkPolicies:
  enabled: true

  # Web app receives traffic from the gateway
  ingress:
    to:
      web:8080: # Web server listens on port 8080
        from:
          definition:
            gateway: true

  # Web app connects to backend services
  egress:
    from:
      web:
        to:
          k8s:
            backend/api:3000: true # API service
            cache/redis:6379: true # Redis cache
          cidr:
            0.0.0.0/0:443: true # External HTTPS APIs
```

### Microservices Architecture

A more complex setup with multiple services:

```yaml
networkPolicies:
  enabled: true
  prependReleaseName: true # Prefix policy names with release name
```

```yaml
networkPolicies:
  # Frontend service configuration
  ingress:
    to:
      frontend:8080:
        from:
          definition:
            gateway: true # Receive traffic from gateway on port 8080

  egress:
    from:
      frontend:
        to:
          k8s:
            backend/api:8080: true # Connect to API on port 8080
```

```yaml
networkPolicies:
  # API service configuration
  egress:
    from:
      api:
        to:
          k8s:
            database/postgres:5432: true # Connect to database
          cidr:
            52.84.0.0/16:443: true # External API calls on port 443
```

```yaml
networkPolicies:
  # Database configuration
  ingress:
    to:
      postgres:5432: # PostgreSQL port
        from:
          k8s:
            backend/api: true # Only accept from API service
```

### Multi-Namespace Setup

When services span multiple namespaces:

```yaml
networkPolicies:
  enabled: true

  # Allow all pods to connect to shared services with specific ports
  egress:
    from:
      "*": # Wildcard applies to all pods
        to:
          k8s:
            shared-services/cache:6379: true # Redis port
            shared-services/queue:5672: true # RabbitMQ port
            logging/elasticsearch:9200: true # Elasticsearch

  # API service with multiple access points
  ingress:
    to:
      api:8080: # HTTP API port
        from:
          k8s:
            frontend/*: true # Any pod from frontend namespace
            admin/dashboard: true # Admin dashboard access
      api:8443: # HTTPS API port
        from:
          k8s:
            external/gateway: true # External gateway only
```

## Advanced Features

Once you're comfortable with the basics, you can use these advanced features:

### Protocol Support

Specify protocols when needed (TCP is default):

```yaml
networkPolicies:
  egress:
    from:
      app:
        to:
          k8s:
            udp://dns-server/dns:53: true # UDP traffic
            tcp://backend/api:443: true # Explicit TCP

  ingress:
    to:
      udp://syslog:514: # UDP syslog receiver
        from:
          k8s:
            "*/*": true # Any pod from any namespace
```

### Advanced Port Patterns

Beyond the basic port specifications, you can use more complex patterns:

```yaml
networkPolicies:
  # Multiple ports array
  egress:
    from:
      app:
        to:
          k8s:
            backend/api:[8080,8443]: true # HTTP and HTTPS
            monitoring/stats:[9090,9100]: true # Multiple metric ports

  # Port ranges
  ingress:
    to:
      api:8080-8090: # Accept on port range
        from:
          k8s:
            frontend/*: true
      api:443: # Separate rule for HTTPS
        from:
          k8s:
            frontend/*: true
            monitoring/prometheus: true

  # Combining protocols with ports
  egress:
    from:
      dns-client:
        to:
          k8s:
            udp://kube-system/coredns:53: true # UDP DNS
            tcp://backend/api:443: true # Explicit TCP
```

### Custom Pod Selectors

Override the default pod selector behavior:

```yaml
networkPolicies:
  egress:
    from:
      my-app:
        podSelector: # Custom selector instead of app.kubernetes.io/name
          matchLabels:
            component: worker
            tier: backend
        to:
          k8s:
            database/postgres:5432: true # PostgreSQL port
```

### Custom Definitions

Create reusable rule definitions:

```yaml
networkPolicies:
  egress:
    definitions:
      external-api:
        to:
          - ipBlock:
              cidr: 52.84.0.0/16
        ports:
          - port: 443
            protocol: TCP
          - port: 8443
            protocol: TCP
    from:
      app:
        to:
          definition:
            external-api: true # Reference your definition

  ingress:
    definitions:
      internal-monitoring:
        from:
          - namespaceSelector:
              matchLabels:
                purpose: monitoring
            podSelector:
              matchLabels:
                app: prometheus
    to:
      app:9090: # Metrics port on local pod
        from:
          definition:
            internal-monitoring: true
```

### Spec Literals

For complex scenarios not covered by any of the shorthands, use a raw
NetworkPolicy ingress/egress spec:

```yaml
networkPolicies:
  egress:
    from:
      app:
        to:
          literal:
            prod-or-staging:
              enabled: true
              spec: # Raw Kubernetes NetworkPolicy egress spec
                - to:
                    - namespaceSelector:
                        matchExpressions:
                          - key: environment
                            operator: In
                            values: ["production", "staging"]
                      podSelector:
                        matchLabels:
                          tier: backend
                  ports:
                    - port: 443
                      protocol: TCP
                    - port: 8443
                      protocol: TCP
```

### Additional Policies

For absolute control of the network policies, they can be provided directly.

```yaml
networkPolicies:
  additionalPolicies: # Raw NetworkPolicy resources
    - name: custom-policy
      labels:
        custom: label
      annotations:
        description: "Custom network policy"
      spec:
        podSelector:
          matchLabels:
            role: frontend
        policyTypes:
          - Egress
        egress:
          - to:
              - ipBlock:
                  cidr: 10.0.0.0/8
            ports:
              - port: 443
                protocol: TCP
```

### SPIFFE-based AuthorizationPolicies

When using Istio service mesh, you can generate SPIFFE-based
AuthorizationPolicies alongside NetworkPolicies for enhanced security using
mutual TLS (mTLS) identity verification.

#### Enabling AuthorizationPolicies

AuthorizationPolicies are generated when:

1. `networkPolicies.ingress.generateAuthorizationPolicies` is set to `true`
2. A service account identity is specified in the ingress rule using the `@`
   prefix

```yaml
networkPolicies:
  enabled: true
  ingress:
    generateAuthorizationPolicies: true # Enable AuthorizationPolicy generation
    to:
      # Standard NetworkPolicy only (no identity specified)
      api:
        from:
          k8s:
            backend/worker: true

      # NetworkPolicy + AuthorizationPolicy (identity specified)
      secure-api:
        from:
          # The service account "api-sa" must exist in the "backend" namespace
          k8s:
            api-sa@backend/worker: true
```

#### How AuthorizationPolicy Generation Works

When you specify an identity prefix (e.g., `api-sa@`), the framework:

1. Generates a standard NetworkPolicy for L3/L4 network isolation
2. Generates an Istio AuthorizationPolicy that enforces SPIFFE identity
   verification

The AuthorizationPolicy uses the SPIFFE ID format:
`cluster.local/ns/<namespace>/sa/<service-account>`

#### AuthorizationPolicy Examples

**Basic Identity-based Access:**

```yaml
networkPolicies:
  ingress:
    generateAuthorizationPolicies: true
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

**Port-specific Access with Identity:**

```yaml
networkPolicies:
  ingress:
    generateAuthorizationPolicies: true
    to:
      tcp://api:8443:
        from:
          k8s:
            frontend-sa@frontend/web: true
```

**Multiple Ports with Identity:**

```yaml
networkPolicies:
  ingress:
    generateAuthorizationPolicies: true
    to:
      "database:[5432,5433]":
        from:
          k8s:
            db-client-sa@backend/app: true
```

**Custom Pod Selectors with Identity:**

```yaml
networkPolicies:
  ingress:
    generateAuthorizationPolicies: true
    to:
      api-service:
        podSelector:
          matchLabels:
            tier: api
            version: v2
        from:
          k8s:
            client-sa@frontend/webapp: true
```

#### Important Notes

1. **Service Account Must Exist**: The specified service account (e.g.,
   `api-sa`) must exist in the source namespace
2. **Istio Required**: AuthorizationPolicies require Istio to be installed and
   both local and remote pods be part of the mesh
3. **mTLS Enabled**: Istio must be configured with mTLS for SPIFFE identity
   verification to work
4. **Backward Compatible**: If `generateAuthorizationPolicies` is false or no
   identity is specified, only NetworkPolicies are created

## Labels and Annotations

All generated policies include these labels:

- `network-policies.bigbang.dev/source: bb-common`
- `network-policies.bigbang.dev/direction: <egress|ingress>`

They'll also include various `generated.network-policies.bigbang.dev`
annotations based on their exact configuration.

## Migration Guide

The bb-common chart can be consumed in two ways: as a **subchart** or as a
**library chart**. This section provides comprehensive migration examples for
both approaches.

### Using bb-common as a Subchart

When using bb-common as a subchart, you include it in your chart's dependencies
and configure it through your values.

#### Step 1: Add bb-common to Chart.yaml

```yaml
# Chart.yaml
apiVersion: v2
name: my-app
version: 1.0.0
dependencies:
  - name: bb-common
    version: "<version>"
    repository: oci://registry1.dso.mil/bigbang
```

#### Step 2: Configure Network Policies in values.yaml

```yaml
# values.yaml
bb-common:
  networkPolicies:
    enabled: true
    egress:
      from:
        my-app:
          to:
            k8s:
              backend/api:8080: true
```

### Using bb-common as a Library Chart

When using bb-common as a library, you can include its templates directly in
your own templates.

#### Step 1: Add bb-common as a library dependency

```yaml
# Chart.yaml
apiVersion: v2
name: my-app
version: 1.0.0
dependencies:
  - name: bb-common
    version: "<version>"
    repository: oci://registry1.dso.mil/bigbang
```

#### Step 2: Include the network policy templates

```yaml
# templates/bigbang/network-policies.yaml
{{- include "bb-common.network-policies.render" . }}
```

#### Step 3: Configure Network Policies in values.yaml

```yaml
# values.yaml
networkPolicies:
  enabled: true
  egress:
    from:
      my-app:
        to:
          k8s:
            backend/api:8080: true
```

### Migration Examples

#### Basic Pod-to-Pod Communication

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: backend
          podSelector:
            matchLabels:
              app.kubernetes.io/name: api
      ports:
        - port: 8080
          protocol: TCP
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  egress:
    from:
      frontend:
        to:
          k8s:
            backend/api:8080: true
```

#### Multiple Pods and Ports

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-egress-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: api
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: database
          podSelector:
            matchLabels:
              app.kubernetes.io/name: postgres
      ports:
        - port: 5432
          protocol: TCP
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: cache
          podSelector:
            matchLabels:
              app.kubernetes.io/name: redis
      ports:
        - port: 6379
          protocol: TCP
    - to:
        - ipBlock:
            cidr: 52.84.0.0/16
      ports:
        - port: 443
          protocol: TCP
        - port: 8443
          protocol: TCP
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  egress:
    from:
      api:
        to:
          k8s:
            database/postgres:5432: true
            cache/redis:6379: true
          cidr:
            52.84.0.0/16:[443,8443]: true
```

#### Complex Ingress Rules

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-ingress-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
          podSelector:
            matchLabels:
              app.kubernetes.io/name: web
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: admin
      ports:
        - port: 8080
          protocol: TCP
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring
          podSelector:
            matchLabels:
              app.kubernetes.io/name: prometheus
      ports:
        - port: 9090
          protocol: TCP
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  ingress:
    to:
      api:8080:
        from:
          k8s:
            frontend/web: true
            admin/*: true # Any pod from admin namespace
      api:9090:
        from:
          k8s:
            monitoring/prometheus: true
```

#### Wildcard Namespace Selectors

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-any-namespace
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: shared-service
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector: {}
          podSelector:
            matchLabels:
              app.kubernetes.io/name: client
      ports:
        - port: 8080
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  ingress:
    to:
      shared-service:8080:
        from:
          k8s:
            "*/client": true # client pods from any namespace
```

#### CIDR Blocks with Exceptions

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: internet-egress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: web
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
              - 169.254.169.254/32
      ports:
        - port: 443
          protocol: TCP
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  egress:
    from:
      web:
        to:
          cidr:
            0.0.0.0/0:443: true # Metadata endpoint blocked automatically
```

##### Overriding the excluded CIDRs

This metadata endpoint exclusion is configurable. If you need to override it,
you can set the `networkPolicies.egress.excludeCIDRs` value to a list of your
choosing. The framework will automatically identify overlaps and apply the
needed `except` items to the generated `ipBlock` keys.

```yaml
networkPolicies:
  enabled: true
  egress:
    excludeCIDRs:
      - 10.1.2.3/32
    from:
      web:
        to:
          cidr:
            # This network policy will automatically except
            # the excluded CIDR because it's contained within
            # this subnet.
            10.1.0.0/16:80: true
            # This network policy will not. The excluded CIDR is
            # not contained within this subnet.
            10.2.0.0/16:80: true
```

#### Nonstandard Pod Selectors

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: worker-egress
spec:
  podSelector:
    matchLabels:
      component: worker
      tier: backend
      version: v2
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: queue
      ports:
        - port: 5672
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  egress:
    from:
      workers:
        podSelector:
          matchLabels:
            component: worker
            tier: backend
            version: v2
        to:
          k8s:
            queue/*:5672: true
```

#### Match Expressions

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: complex-selectors
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchExpressions:
              - key: environment
                operator: In
                values: ["production", "staging"]
          podSelector:
            matchExpressions:
              - key: tier
                operator: NotIn
                values: ["database"]
      ports:
        - port: 8080
```

**Migrated to bb-common (using spec literal):**

```yaml
networkPolicies:
  enabled: true
  ingress:
    to:
      api:8080:
        from:
          complex-selector:
            enabled: true
            spec:
              - from:
                  - namespaceSelector:
                      matchExpressions:
                        - key: environment
                          operator: In
                          values: ["production", "staging"]
                    podSelector:
                      matchExpressions:
                        - key: tier
                          operator: NotIn
                          values: ["database"]
```

#### UDP and Mixed Protocols

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: dns-and-api
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: app
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: coredns
      ports:
        - port: 53
          protocol: UDP
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: backend
      ports:
        - port: 443
          protocol: TCP
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  egress:
    from:
      app:
        to:
          k8s:
            udp://kube-system/coredns:53: true
            backend/*:443: true
```

#### Port Ranges

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: metrics-ports
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: metrics-server
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring
      ports:
        - port: 9090
          protocol: TCP
        - port: 9091
          protocol: TCP
        - port: 9092
          protocol: TCP
        - port: 9093
          protocol: TCP
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  ingress:
    to:
      metrics-server:9090-9093: # Port range
        from:
          k8s:
            monitoring/*: true
```

#### Multiple Policy Types

**Original NetworkPolicies (multiple files):**

```yaml
# egress-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-egress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: app
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: backend
      ports:
        - port: 8080

# ingress-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-ingress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: app
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
      ports:
        - port: 3000
```

**Migrated to bb-common (single configuration):**

```yaml
networkPolicies:
  enabled: true
  egress:
    from:
      app:
        to:
          k8s:
            backend/*:8080: true
  ingress:
    to:
      app:3000:
        from:
          k8s:
            frontend/*: true
```

#### Empty Selectors (Allow All)

**Original NetworkPolicy:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-ingress-to-public
spec:
  podSelector:
    matchLabels:
      exposure: public
  policyTypes:
    - Ingress
  ingress:
    - {} # Allow from anywhere
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  ingress:
    to:
      public-service:
        podSelector:
          matchLabels:
            exposure: public
        from:
          k8s:
            */*: true # Allow from any pod in any namespace
          cidr:
            0.0.0.0/0: true # Allow from external sources
```

#### Combining with Default Policies

**Original setup with multiple policies:**

```yaml
# deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
spec:
  podSelector: {}
  policyTypes:
    - Egress

# allow-dns.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - port: 53
          protocol: UDP

# app-specific.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: app
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: backend
```

**Migrated to bb-common:**

```yaml
networkPolicies:
  enabled: true
  # Defaults handle deny-all and DNS automatically
  egress:
    defaults:
      enabled: true # Includes denyAll and allowKubeDns; already `true` by default
    from:
      app:
        to:
          k8s:
            backend/*: true
```

### Migration Strategy

1. **Start with defaults**: Enable default policies first to establish baseline
   security; setting `networkPolicies.enabled` to `true` will do this
   automatically
2. **Migrate incrementally**: Convert one service and one network policy at a
   time
3. **Switch to recommended labels**: If the existing netpols use non-standard
   k8s labels, check if those workloads can be selected with
   [the recommended labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/#labels)
   instead, allowing the shorthand syntax to be used in place of more verbose
   rules
4. **Test thoroughly**: Use `helm template` to verify generated policies
5. **Monitor connectivity**: Watch application logs during rollout
6. **Leverage definitions**: Create custom definitions for repeated patterns
7. **Use additionalPolicies**: For policies that don't fit the DSL
8. **Debugging**: Keep original policies during migration and compare with
   `kubectl diff`

## Troubleshooting

Common issues and solutions:

1. **Policies not created**: Ensure `networkPolicies.enabled: true`
2. **DNS resolution failing**: Make sure `allowKubeDns` is not disabled in
   egress defaults
3. **Istio communication blocked**: Make sure `allowIstiod` is not disabled in
   egress defaults
4. **Policy naming conflicts**: Use `prependReleaseName: true` for multiple
   releases
5. **Complex selectors not working**: Use spec literals for advanced matching
6. **Connection refused**: Ensure you've specified the correct port in your
   rules
7. **Partial connectivity**: Check if you need multiple ports (e.g., `[80,443]`)

For debugging, use:

```bash
# List all policies
kubectl get netpol -n <namespace>
```

```bash
# Describe a specific policy
kubectl describe netpol <policy-name> -n <namespace>
```

```bash
# Test connectivity
kubectl exec -n <namespace> <pod> -- curl <target>:<port>
```

```bash
# Test specific port connectivity
kubectl exec -n <namespace> <pod> -- nc -zv <target> <port>
```
