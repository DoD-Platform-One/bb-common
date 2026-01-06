# Routes Documentation

The bb-common Helm chart provides a comprehensive routes framework that
simplifies the creation and management of Istio service mesh resources for
ingress traffic routing.

## Table of Contents

<!--toc:start-->

- [Routes Documentation](#routes-documentation)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Inbound Routes](#inbound-routes)
    - [Quick Start](#quick-start)
    - [Generated Resources](#generated-resources)
      - [VirtualService](#virtualservice)
      - [ServiceEntry](#serviceentry)
      - [NetworkPolicy](#networkpolicy)
      - [AuthorizationPolicy](#authorizationpolicy)
    - [Automatic Selector Inference](#automatic-selector-inference)
  - [Outbound Routes](#outbound-routes)
    - [Quick Start](#quick-start-1)
    - [Generated Resources](#generated-resources-1)
      - [ServiceEntry](#serviceentry-1)
    - [Configuration Options](#configuration-options)
  - [Examples](#examples)
    - [Inbound Examples](#inbound-examples)
      - [Simple Application Routing](#simple-application-routing)
      - [Multiple Services](#multiple-services)
      - [Advanced HTTP Rules](#advanced-http-rules)
      - [Custom Gateway Configuration](#custom-gateway-configuration)
      - [Labels and Annotations](#labels-and-annotations)
    - [Outbound Examples](#outbound-examples)
      - [Basic Outbound Route](#basic-outbound-route)
      - [Custom Ports and Protocols](#custom-ports-and-protocols)
      - [Mesh Internal Services](#mesh-internal-services)
  - [Migration Guide](#migration-guide)
    - [Migrating from Legacy Istio VirtualServices](#migrating-from-legacy-istio-virtualservices)
    - [Files to Remove](#files-to-remove)
    - [Configuration Changes](#configuration-changes)
      - [1. Add the Routes Template](#1-add-the-routes-template)
      - [2. Values Migration](#2-values-migration)

<!--toc:end-->

## Overview

The routes framework provides two types of routing configurations:

- **Inbound Routes** (`routes.inbound`): Configure ingress traffic routing through Istio gateways to services within your mesh, with automatic security policy generation
- **Outbound Routes** (`routes.outbound`): Register external services for egress traffic, enabling REGISTRY_ONLY outbound traffic policies

## Inbound Routes

Inbound routes handle incoming traffic to your applications through Istio gateways.

### Quick Start

Inbound routes are configured under the `routes.inbound` key in your values file. Here's a basic configuration that creates a secure route with network policies:

```yaml
routes:
  inbound:
    my-app:
      enabled: true                # Enable/disable the route
      gateways:                    # List of Istio gateways
        - istio-gateway/public-ingressgateway
      hosts:                       # List of host domains (supports templating)
        - myapp.example.com
      service: my-app-service      # Target service name (supports templating)
      port: 8080                   # Target service port (supports templating)
      containerPort: 3000          # Optional - container/pod port for NetworkPolicy (defaults to port)
      selector:                    # Optional - defaults to app.kubernetes.io/name: {route-key}
        app.kubernetes.io/name: my-app
      metadata:                    # Custom metadata for all generated resources
        labels: {}                 # Custom labels for all generated resources
        annotations: {}            # Custom annotations for all generated resources
```

This creates a VirtualService that routes traffic from `myapp.example.com` to
the `my-app-service` on port 8080, plus supporting resources for security and
service mesh integration.

**Required fields:**

- `enabled`: Must be `true` to generate resources
- `gateways`: List of Istio gateways (format: `namespace/gateway-name`)
- `hosts`: List of hostnames for routing
- `service`: Target service name
- `port`: Target service port

**Optional:**

- `containerPort`: Target container/pod port number - used for NetworkPolicy when different from service port. When omitted, defaults to `port` value. Supports templating.
- `selector`: Pod selector labels - if omitted, defaults to `app.kubernetes.io/name: {route-key}`. NetworkPolicy and AuthorizationPolicy are automatically generated using this selector for enhanced security
- `metadata`: Custom labels and annotations for all generated resources

## Prerequisites

> **Important**: Routes are **conditionally rendered** based on the availability of Istio Custom Resource Definitions (CRDs) in your cluster.

Routes requires the Istio CRDs to be installed in your Kubernetes cluster. Specifically, routes will only be rendered when the `networking.istio.io/v1` API version is available.

**To verify Istio CRDs are available:**

```bash
kubectl api-versions | grep networking.istio.io/v1
```

You should see `networking.istio.io/v1` in the output. If you don't see this, you need to install Istio before routes can be generated.

## Generated Resources

The routes framework automatically generates multiple Kubernetes resources to provide complete ingress routing functionality. Each enabled route creates a **VirtualService** for traffic routing and a **ServiceEntry** for internal service mesh communication. Additional **NetworkPolicy** and **AuthorizationPolicy** resources are automatically created to secure access to the target service using either an explicit selector or the default `app.kubernetes.io/name: {route-key}` selector.

For a visual representation of how these resources relate to each other, see the [Resource Graph](../RESOURCE_GRAPH.md).

#### VirtualService

A Kubernetes VirtualService is created for each enabled route:

```yaml
# Generated from basic route configuration
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: my-app
  namespace: default
spec:
  gateways:
    - istio-gateway/public-ingressgateway
  hosts:
    - myapp.example.com
  http:
    - route:
        - destination:
            host: my-app-service
            port:
              number: 8080
```

#### ServiceEntry

A ServiceEntry is created to register the inbound route hosts in the service mesh registry.
This is essential when using REGISTRY_ONLY outbound traffic policies, allowing
the mesh to route traffic to external hosts defined in the VirtualService:

```yaml
# Generated for service mesh registry entry
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: my-app-internal
  namespace: default
spec:
  hosts:
    - myapp.example.com
  location: MESH_EXTERNAL
  resolution: DNS
  ports:
    - name: https
      number: 443
      protocol: HTTPS
```

> **Note**: ServiceEntries are particularly important in environments with
> `outboundTrafficPolicy.mode` set to `REGISTRY_ONLY`, where only explicitly
> registered external services are allowed.

#### NetworkPolicy

A NetworkPolicy is automatically generated to allow ingress gateway access:

```yaml
# Generated automatically (using explicit or default selector)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-istio-gateway-my-app
  namespace: default
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: istio-gateway
          podSelector:
            matchLabels:
              app.kubernetes.io/name: public-ingressgateway
              istio: ingressgateway
      ports:
        - port: 8080
          protocol: TCP
```

> **Note**: By default, the NetworkPolicy uses the same port as specified in the `port` field (8080 in this example). If your service port differs from your container/pod port, use the `containerPort` field to specify the actual port the container is listening on. For example, if your service exposes port 80 but your container listens on 8080, set `port: 80` and `containerPort: 8080`. The VirtualService will use port 80, while the NetworkPolicy will use port 8080.

#### AuthorizationPolicy

An AuthorizationPolicy is also automatically created for allowing gateway access to the application pod:

```yaml
# Generated automatically (using explicit or default selector)
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: my-app-public-ingressgateway-authz-policy
  namespace: default
spec:
  action: ALLOW
  selector:
    matchLabels:
      app.kubernetes.io/name: my-app
  rules:
    - from:
        - source:
            namespaces:
              - istio-gateway
            principals:
              - cluster.local/ns/istio-gateway/sa/public-ingressgateway-ingressgateway-service-account
```

### Automatic Selector Inference

When no `selector` is explicitly provided in the route configuration, the system automatically infers one using the Kubernetes standard labeling convention:

```yaml
# Automatic inference example
routes:
  inbound:
    my-service:  # Route key
      enabled: true
      # No selector specified
      gateways:
        - istio-gateway/public-ingressgateway
      hosts:
        - myservice.example.com
      service: my-service
      port: 8080

# Automatically becomes equivalent to:
routes:
  inbound:
    my-service:
      enabled: true
      selector:
        app.kubernetes.io/name: my-service  # Inferred from route key
      # ... rest of configuration
```

This ensures that NetworkPolicy and AuthorizationPolicy resources are always created, even when selectors are not explicitly specified. You can override this behavior by providing an explicit `selector` configuration.

## Outbound Routes

Outbound routes register external services in the Istio service mesh, enabling controlled egress traffic. This is particularly important when using `outboundTrafficPolicy.mode: REGISTRY_ONLY`, where only explicitly registered external services are accessible.

### Quick Start

Outbound routes are configured under the `routes.outbound` key in your values file:

```yaml
routes:
  outbound:
    google:
      enabled: true
      hosts:
        - www.google.com
      ports:
        - number: 443
          name: https
          protocol: HTTPS
```

This creates a ServiceEntry that allows pods in the mesh to communicate with `www.google.com` on port 443.

**Required fields:**

- `enabled`: Must be `true` to generate resources
- `hosts`: List of external hostnames to register

**Optional:**

- `ports`: List of port configurations (defaults to HTTPS/443 if omitted)
- `location`: Service location - `MESH_EXTERNAL` (default) or `MESH_INTERNAL`
- `resolution`: DNS resolution strategy - `DNS` (default), `STATIC`, `DNS_ROUND_ROBIN`, `DYNAMIC_DNS`, or `NONE`
- `metadata`: Custom labels and annotations for the generated ServiceEntry

### Generated Resources

#### ServiceEntry

A ServiceEntry resource is created for each enabled outbound route:

```yaml
# Generated from outbound route configuration
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: google-external
  namespace: default
  labels:
    service-entries.bigbang.dev/source: bb-common
  annotations:
    outbound.service-entries.generated.bigbang.dev/from-route-name: google
spec:
  hosts:
    - www.google.com
  location: MESH_EXTERNAL
  resolution: DNS
  ports:
    - name: https
      number: 443
      protocol: HTTPS
```

> **Note**: The ServiceEntry name is automatically suffixed with `-external` or `-internal` based on the `location` setting.

### Configuration Options

**Location**

- `MESH_EXTERNAL` (default): Service is external to the mesh
- `MESH_INTERNAL`: Service is internal to the mesh

**Resolution**

- `DNS` (default): Use DNS for service discovery
- `STATIC`: Use static IP addresses from the service entry
- `DNS_ROUND_ROBIN`: DNS-based round-robin load balancing
- `DYNAMIC_DNS`: Dynamically resolve DNS
- `NONE`: No resolution - use the address as-is

**Ports**

If no ports are specified, defaults to HTTPS/443. When specifying ports, all three fields are required:

```yaml
ports:
  - number: 443      # Port number (can be templated string or integer)
    name: https      # Port name
    protocol: HTTPS  # Protocol (HTTP, HTTPS, TCP, etc.)
```

## Examples

### Inbound Examples

#### Simple Application Routing

Basic web application exposed through a gateway:

See [routes-simple-application-routing.yaml](../../chart/tests/routes/values/routes-simple-application-routing.yaml) for the complete configuration.

#### Multiple Services

Multiple services with different routing configurations:

See [routes-multiple-services.yaml](../../chart/tests/routes/values/routes-multiple-services.yaml) for the complete configuration.

#### Advanced HTTP Rules

Custom routing with path-based rules:

See [routes-advanced-http-rules.yaml](../../chart/tests/routes/values/routes-advanced-http-rules.yaml) for the complete configuration.

#### Custom Gateway Configuration

Using different gateways for external and internal services:

See [routes-custom-gateway-configuration.yaml](../../chart/tests/routes/values/routes-custom-gateway-configuration.yaml) for the complete configuration.

#### Labels and Annotations

Apply custom labels and annotations to all generated resources using the metadata structure:

See [routes-labels-and-annotations.yaml](../../chart/tests/routes/values/routes-labels-and-annotations.yaml) for the complete configuration.

> **Note**: Custom labels and annotations specified in the route metadata configuration are applied to all generated resources (VirtualService, ServiceEntry, NetworkPolicy, and AuthorizationPolicy).

#### Service and Container Port Discrepancy

When your Kubernetes service port differs from the actual container port, use `containerPort` to ensure NetworkPolicies target the correct port:

```yaml
routes:
  inbound:
    loki:
      enabled: true
      gateways:
        - istio-gateway/public-ingressgateway
      hosts:
        - loki.dev.bigbang.mil
      service: logging-loki-gateway.logging.svc.cluster.local
      port: 80              # Service port (used in VirtualService)
      containerPort: 8080   # Container port (used in NetworkPolicy)
      selector:
        app.kubernetes.io/name: logging-loki
```

This configuration creates:
- A **VirtualService** that routes to the service on port **80**
- A **NetworkPolicy** that allows traffic to the pods on port **8080**

See [routes-container-port.yaml](../../chart/tests/routes/values/routes-container-port.yaml) for the complete configuration.

### Outbound Examples

#### Basic Outbound Route

Allow access to external services with default HTTPS configuration:

```yaml
routes:
  outbound:
    google:
      enabled: true
      hosts:
        - www.google.com
        - google.com
    
    github:
      enabled: true
      hosts:
        - api.github.com
        - github.com
```

#### Custom Ports and Protocols

Define specific ports and protocols for external services:

```yaml
routes:
  outbound:
    database:
      enabled: true
      hosts:
        - db.example.com
      ports:
        - number: 5432
          name: postgres
          protocol: TCP
        - number: 5433
          name: postgres-replica
          protocol: TCP
    
    api-service:
      enabled: true
      hosts:
        - api.example.com
      ports:
        - number: 80
          name: http
          protocol: HTTP
        - number: 443
          name: https
          protocol: HTTPS
```

#### Mesh Internal Services

Register services internal to the mesh with custom resolution:

```yaml
routes:
  outbound:
    internal-service:
      enabled: true
      hosts:
        - internal.service.local
      location: MESH_INTERNAL
      resolution: NONE
      metadata:
        labels:
          environment: production
          team: platform
        annotations:
          description: "Internal service for cross-namespace communication"
```

## Migration Guide

### Migrating from Legacy Istio VirtualServices

If you're migrating from manually defined Istio VirtualServices to the bb-common routes framework, this guide will help you understand the required changes. The following example shows the migration process for the monitoring chart.

### Files to Remove

The following template files should be **deleted** when migrating to routes:

```bash
# Remove individual VirtualService template files
rm chart/templates/bigbang/virtualservices/prometheus-vs.yaml
rm chart/templates/bigbang/virtualservices/alertmanager-vs.yaml
# Remove any other *-vs.yaml files in the virtualservices directory
```

### Configuration Changes

#### 1. Add the Routes Template

Create a new template file that renders all routes:

```yaml
# chart/templates/bigbang/routes.yaml
{{- include "bb-common.routes.render" . }}
```

#### 2. Values Migration

**Old Istio Configuration:**

```yaml
istio:
  enabled: true
  prometheus:
    enabled: true
    gateways:
      - istio-gateway/public-ingressgateway
    hosts:
      - prometheus.{{ .Values.domain }}
    service: my-service-name
    port: 9090
    namespace: monitoring

  alertmanager:
    enabled: true
    gateways:
      - istio-gateway/public-ingressgateway
    hosts:
      - alertmanager.{{ .Values.domain }}
    service: my-alertmanager-service
    port: 9093
    namespace: monitoring

  hardened:
    enabled: true
    customServiceEntries:
    - name: "allow-google"
      enabled: true
      spec:
        hosts:
          - google.com
        location: MESH_EXTERNAL
        ports:
          - number: 443
            protocol: TLS
            name: https
        resolution: DNS
```

**New Routes Configuration:**

```yaml
routes:
  inbound:
    prometheus:
      enabled: true
      gateways:
        - istio-gateway/public-ingressgateway
      hosts:
        - prometheus.{{ .Values.domain }}
      service: "{{ include \"kube-prometheus-stack.fullname\" . }}-prometheus.{{ .Release.Namespace }}.svc.cluster.local"
      port: "{{ .Values.prometheus.service.port }}"
      selector:
        app.kubernetes.io/name: prometheus

    alertmanager:
      enabled: true
      gateways:
        - istio-gateway/public-ingressgateway
      hosts:
        - alertmanager.{{ .Values.domain }}
      service: "{{ include \"kube-prometheus-stack.fullname\" . }}-alertmanager.{{ .Release.Namespace }}.svc.cluster.local"
      port: "{{ .Values.alertmanager.service.port }}"
      selector:
        app.kubernetes.io/name: alertmanager
  outbound:
    google:
      enabled: true
      hosts:
        - google.com
```
