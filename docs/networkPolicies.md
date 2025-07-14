## Network Policy Overview

The following section is an example of what the `networkPolicies` section for a given package will look like:

```
networkPolicies:
  enabled: true
  ingressLabels:
    app: istio-ingressgateway
    istio: ingressgateway
  # See `kubectl cluster-info` and then resolve to IP
  bundled:
    base:
      enabled: true
    conditional:
      enabled: true
    kubeApiAccess:
      enabled: true
      controlPlaneCidrs:
      - 10.0.0.0/8
      - 172.16.0.0/12
      - 192.168.0.0/16
      # A policy will be generated for each item in `pods` targeting pods with a label
      # selector `app.kubernetes.io/name: pod`. If omitted it will generate a single policy
      # selecting all pods in the namespace.
      pods:
      - grafana
    dynamic:
      enabled: true
      ingress:
        sidekiq:
          selector:
            app: sidekiq
          ports:
            - port: 8080
              protocol: TCP
        gitlab-pages:
          selector:
            app: gitlab-pages
          ports:
            - port: 8090
              protocol: TCP
      metricsPorts:
      - port: 1234
      ssoCidrs:
      - 0.0.0.0/0
      databaseCidrs:
      - 10.0.0.0/8
      - 172.16.0.0/12
      - 192.168.0.0/16
  package:
    allow-prometheus-egress:
      enabled: true
      direction: Egress
      to: prometheus.monitoring
      ports:
      - port: 9090
        protocol: TCP
    allow-grafana-egress:
      enabled: true
      direction: Egress
      from: kiali.kiali
      to: grafana.monitoring
      ports:
      - port: 3000
    allow-jaeger-egress:
      enabled: true
      spec:
        podSelector: {}
        policyTypes:
        - Egress
        egress:
        - to:
          - namespaceSelector:
              matchLabels:
                app.kubernetes.io/name: jaeger
            podSelector:
              matchLabels:
                app: jaeger
          ports:
          - port: 16686      
  additionalPolicies: []
```

### Netowrk Policy Naming Conventions

All policies should follow the same conventions to ensure a more polished and uniform look.  The convention is as follows:

`action`-`object`-`operation`

Where `action` is either `allow` or `deny`, `object` is the service in question (i.e. tempo, postgresql, s3, etc), and `operation` is either `egress` or `ingress` depending on the policy.  

If the policy is both ingress and egress then `operation` should be left off entirely (i.e. `deny-all`).  

If the network policy is very specific (i.e. Kiali to postgresql) then it might look something like this:

`allow-kiali-postgresql-egress`

Where `object` becomes `objectFrom-objectTo`.

### Network Policy Details

#### `networkPolicies.bundled.base`

This section is dedicated to network policies that belong in all packages regardless of their function and include the following policies:

- Allow all traffic within the namespace
- Allow all traffic to Kubernetes DNS
- Deny all unspecified traffic

All of the above policies can be found in the chart/templates/networkPolicies/_base.yaml file and are defined as `bb-common.netpols.base`.

#### `networkPolicies.bundled.conditional`

This section is dedicated to network policies that exist in almost all packages and are enabled base on certain conditions (i.e. `monitoring.enabled` or `tracing.enabled`):

- Allow all traffic to Istiod
- Allow inbound traffic for Prometheus monitoring of istio sidecar and redis (if enabled)
- Allow all external traffic from helm test related pods
- Allow all external traffic to tempo for tracing
- Allow all traffic related to MinIO

These policies are located in the chart/templates.networkPolicies/_conditional.yaml and are defined as `bb-common.netpols.conditional`.

#### `networkPolicies.bundled.dynamic`

This section is reserved for network policies that require information specific to the package or should allow users to input information based on their environment.

- Allow all traffic to SSO
- Allow all traffic from Ingress Gateway to ingress port(s)
- Allow all traffic to port(s) used for metrics
- Allow all traffic outbound to PostgreSQL if local database is not in use

> [!NOTE]
> If a given package doesn't have an associated database or have an ingress gateway it is not necessary to include those cidr sections.

> [!NOTE]
> The `newtorkPolicies.bundled.kubeApiAccess` value also falls within this category, however, as it is so common for packages that need system-level access it has its own section dedicated to it.  If a package does not require access to the Kubernetes API it should be disabled by default.

#### `networkPolicies.package`

These are policies that are specific to a package and can be added in two different ways.  Both ways require the following settings:

`name` and `name`.enabled

The `name` should simply be descriptive of what the policy is used for as laid out in the naming conventions section earlier:

`action`-`name`-`direction`

There are two different ways these rules can be added:

##### Package Template Shorthand

| Value | Description |
| --- | --- |
| direction | Enumeration (Ingress or Egress) |
| from | Required when direction is Ingress; Optional when Egress |
| to | Required when direction is Egress; Optional when Ingress |
| ports | List of ports to allow |

The `from` and `to` both follow the same convention of `pod`.`namespace`

Example of the `package` section using the shorthand method:

```
    allow-prometheus-mesh-egress:
      enabled: true
      direction: Egress
      to: prometheus.monitoring
      ports:
      - port: 9090
    allow-grafana-mesh-egress:
      enabled: true
      direction: Egress
      from: kiali.kiali
      to: grafana.monitoring
      ports:
      - port: 3000
        protocol: TCP
```

> [!NOTE]
> The `namespace` may not always be used depending on the situation but is always required for the sake of keeping things consistent.  Additionally, this specific method will only work if the workloads follow standard Kubernetes naming conventions as it uses the app.kubernetes.io/name labels (which is used in the vast majority of custom network policies) for pod workloads.  Namepsace workloads will utilize the kubernetes.io/metadata.name label which should exist by default across all namespaces.

##### Newtork Policy Passthrough

If a package has very specific requirements, can not use standard Kubernetes labels, requires access to an entire CIDR, or is using both Ingress and Egress then the entire policy can be passed to the `spec` value like shown below:

```
networkPolicies:
  enabled: true
  package:
    allow-tempo-egress:
      enabled: true
      spec:
        podSelector: {}
        policyTypes:
        - Egress
        egress:
        - to:
          - namespaceSelector:
              matchLabels:
                app.kubernetes.io/name: tempo
            podSelector:
              matchLabels:
                app: tempo
          ports:
          - port: 9411
```

This method can also be used for ease of migrating to the library chart.  However, it is highly recommended to use the first option whenever possible to keep the values.yaml file as clean and concise as possible.

> [!NOTE]
> The two methods cannot be used in a hybrid manner, but you can add some policies that use the shorthand approach and still have others use the full passthrough method.

#### `networkPolicies.additionalPolicies`

This section was present prior to this lilbrary and remains unchanged.  It allows users to add in their own specific network policies.