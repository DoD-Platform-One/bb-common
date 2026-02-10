# BB-Common Documentation

## Available Documentation

- **[Network Policies](network-policies/README.md)** - Comprehensive guide to
  the network policy framework including shorthand syntax, configuration
  examples, and migration guides.

- **[Self Testing](self-test/README.md)** - Instructions for setting up and
  using the self-testing framework.

- **[Routes](routes/README.md)** - Complete guide to the routes framework for
  Istio service mesh resources including VirtualServices, ServiceEntries,
  NetworkPolicies, and AuthorizationPolicies for ingress traffic routing.

- **[Authorization Policies](authorization-policies/README.md)** - Guide to
  generating and configuring Istio AuthorizationPolicies alongside NetworkPolicies
  for comprehensive service mesh security.

- **[Resource Graph](RESOURCE_GRAPH.md)** - Visual representation of how
  bb-common components interact and generate Kubernetes resources.

- **[Migration Guide](MIGRATION_GUIDE.md)** - Full guide on migrating a package
  with static resources for network policies, authorization policies, virtual services,
  and service entries to using bb-common as a library chart to dynamically generate 
  the same resources.
