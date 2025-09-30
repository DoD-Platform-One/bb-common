# Routes Documentation

The bb-common Helm chart provides a comprehensive routes framework that
simplifies the creation and management of Istio service mesh resources for
ingress traffic routing.

## Table of Contents

<!--toc:start-->

- [Routes Documentation](#routes-documentation)
  - [Table of Contents](#table-of-contents)
  - [Quick Start](#quick-start)
  - [Generated Resources](#generated-resources)
    - [VirtualService](#virtualservice)
    - [ServiceEntry](#serviceentry)
    - [NetworkPolicy](#networkpolicy)
    - [AuthorizationPolicy](#authorizationpolicy)
  - [Automatic Selector Inference](#automatic-selector-inference)
  - [Examples](#examples)
    - [Simple Application Routing](#simple-application-routing)
    - [Multiple Services](#multiple-services)
    - [Advanced HTTP Rules](#advanced-http-rules)
    - [Custom Gateway Configuration](#custom-gateway-configuration)
    - [Labels and Annotations](#labels-and-annotations)
  - [Migration Guide](#migration-guide)
    - [Migrating from Legacy Istio VirtualServices](#migrating-from-legacy-istio-virtualservices)
    - [Files to Remove](#files-to-remove)
    - [Configuration Changes](#configuration-changes)
      - [1. Add the Routes Template](#1-add-the-routes-template)
      - [2. Values Migration](#2-values-migration)

<!--toc:end-->

## Quick Start

Routes are configured under the `routes.inbound` key in your values file. Here's a basic configuration that creates a secure route with network policies:

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

- `selector`: Pod selector labels - if omitted, defaults to `app.kubernetes.io/name: {route-key}`. NetworkPolicy and AuthorizationPolicy are automatically generated using this selector for enhanced security

## Generated Resources

The routes framework automatically generates multiple Kubernetes resources to provide complete ingress routing functionality. Each enabled route creates a **VirtualService** for traffic routing and a **ServiceEntry** for internal service mesh communication. Additional **NetworkPolicy** and **AuthorizationPolicy** resources are automatically created to secure access to the target service using either an explicit selector or the default `app.kubernetes.io/name: {route-key}` selector.

For a visual representation of how these resources relate to each other, see the [Resource Graph](../RESOURCE-GRAPH.md).

### VirtualService

A Kubernetes VirtualService is created for each enabled route:

```yaml
# Generated from basic route configuration
apiVersion: networking.istio.io/v1beta1
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

### ServiceEntry

A ServiceEntry is created to register external services in the service mesh registry.
This is essential when using REGISTRY_ONLY outbound traffic policies, allowing
the mesh to route traffic to external hosts defined in the VirtualService:

```yaml
# Generated for service mesh registry entry
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: my-app-service-entry
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

### NetworkPolicy

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

### AuthorizationPolicy

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

## Automatic Selector Inference

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

## Examples

### Simple Application Routing

Basic web application exposed through a gateway:

See [routes-simple-application-routing.yaml](../chart/tests/values/routes-simple-application-routing.yaml) for the complete configuration.

### Multiple Services

Multiple services with different routing configurations:

See [routes-multiple-services.yaml](../chart/tests/values/routes-multiple-services.yaml) for the complete configuration.

### Advanced HTTP Rules

Custom routing with path-based rules:

See [routes-advanced-http-rules.yaml](../chart/tests/values/routes-advanced-http-rules.yaml) for the complete configuration.

### Custom Gateway Configuration

Using different gateways for external and internal services:

See [routes-custom-gateway-configuration.yaml](../chart/tests/values/routes-custom-gateway-configuration.yaml) for the complete configuration.

### Labels and Annotations

Apply custom labels and annotations to all generated resources using the metadata structure:

See [routes-labels-and-annotations.yaml](../chart/tests/values/routes-labels-and-annotations.yaml) for the complete configuration.

> **Note**: Custom labels and annotations specified in the route metadata configuration are applied to all generated resources (VirtualService, ServiceEntry, NetworkPolicy, and AuthorizationPolicy).

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
```
