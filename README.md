# BB-Common Library Chart

A Helm library chart providing standardized Kubernetes resource templates for
Platform One Big Bang packages.

## Overview

BB-Common is a library chart designed to reduce code duplication and accelerate
package development within the
[Platform One Big Bang](https://p1.dso.mil/bigbang) ecosystem. Big Bang is the
Department of Defense's declarative continuous delivery tool for deploying
DoD-hardened and approved packages into Kubernetes clusters.

This chart provides reusable templates and abstractions for common Kubernetes
resources, starting with a sophisticated network policy framework that
simplifies security configuration while maintaining compliance with DoD
DevSecOps requirements.

## Features

### Network Policies

The centerpiece of bb-common is its comprehensive network policy system that
transforms complex Kubernetes NetworkPolicy resources into intuitive,
declarative configurations:

- **Shorthand Syntax**: Express complex network rules with simple notation like
  `backend/api:8080` or `10.0.0.0/8:443`
- **Security by Default**: Automatic deny-all policies with selective allow
  rules following zero-trust principles
- **Built-in Definitions**: Pre-configured rules for common patterns (Istio
  gateway, monitoring, DNS)
- **Smart Defaults**: Automatically handles DNS resolution, in-namespace
  communication, and Istio control plane traffic
- **Full Flexibility**: Support for raw NetworkPolicy specs when needed

[Learn more about network policies →](docs/network-policies/README.md)

## Installation

### As a Subchart

Add bb-common to your chart dependencies:

```yaml
# Chart.yaml
dependencies:
  - name: bb-common
    version: "<version>"
    repository: oci://registry1.dso.mil/bigbang
```

Then configure in your values:

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

### As a Library Chart

For more control, use bb-common as a library:

```yaml
# Chart.yaml
dependencies:
  - name: bb-common
    version: "<version>"
    repository: oci://registry1.dso.mil/bigbang
```

Include templates in your chart:

```yaml
# templates/bigbang/network-policies.yaml
{{- include "bb-common.network-policies.render" . }}
```

Configure directly in values:

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

## Development

### Prerequisites

- Helm 3.x
- [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin for
  testing

### Running Tests

```bash
cd chart
helm dep update
helm unittest .
```

### Testing Template Generation

Preview generated resources:

```bash
cd chart
helm template my-release . --values values.yaml
```

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## Roadmap

Future additions to bb-common will include:

- **Authorization Policies**: Istio authorization templates
- **Service Entries**: External service registration
- **Peer Authentications**: mTLS configuration
- **Virtual Services**: Traffic management rules

The goal is to provide a comprehensive library that standardizes Big Bang
integration while reducing boilerplate across all packages.

## License

See [LICENSE](LICENSE) for licensing information.

## Support

For issues, feature requests, or questions:

- Review the [documentation](docs/README.md)
- Check existing
  [issues and discussions](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/issues)
- Contact the Big Bang team through official Platform One channels
