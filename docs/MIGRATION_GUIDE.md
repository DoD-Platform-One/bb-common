# Migration Guide

## Table of Contents

<!--toc:start-->
- [Migration Guide](#migration-guide)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Recommended Reading](#recommended-reading)
    - [Migration Overview](#migration-overview)
  - [Package Updates](#package-updates)
  - [Umbrella Template Updates](#umbrella-template-updates)
  - [Final Steps](#final-steps)
  - [Appendix](#appendix)
    - [Network Policy Examples](#network-policy-examples)
<!--toc:end-->

## Overview

This guide covers the changes required to convert a package with statically defined resources to using dynamically generated resources 
created by the bb-common chart when used as a library chart. Prior to getting started, please reference [this section](../README.md#as-a-library-chart) 
to add bb-common and its associated include files.

### Recommended Reading

Prior to starting the migration it is highly recommended to read the sections outlined below as all of 
these concepts will be applied throughout the migration process:

- [How Network Policy Generation Works](/docs/network-policies?ref_type=heads#how-it-works)
- [Default Network Policies](/docs/network-policies/README.md#default-policies)
- [Authorization Policy Generation](/docs/network-policies?ref_type=heads#how-it-works)
- [Default Authorization Policies](/docs/authorization-policies/README.md#basic-configuration)
- [Virtual Services](/docs/routes?ref_type=heads#inbound-routes)
- [Service Entries](/docs/routes?ref_type=heads#outbound-routes)

### Migration Overview

It is recommened to install the package as-is in a dev cluster first to establish a healthy baseline. Everything mentioned
in the package's development maintenance documentation should be 100% functional at this point. Additionally, it is recommended
to run a helm test against the package to make sure its test is in a healthy state as well.

```bash
helm test kiali-kiali -n bigbang
```

The easiest way to migrate to bb-common is to migrate resources incrementally starting with network policies as these
will also be used to generate the authorization policies. Once complete, all other Istio resources should be configured
with virtual services and service entries done last.

All network policies that are required in order for the package to function should be included in the values.yaml 
for that specific package. Additional policies can also be placed in the values.yaml for the package, however, they
should always be set to `false` by default as there is no way to apply logic at this point. This allows the policies 
to show up within the package's README.md even though they are being controlled in that package's umbrella template.

Once all templating looks correct, create a branch on the bigbang repository and update the package's template. This is 
where all of the logic for enabling/disabling network policies will exist. It is also where all global definitions will 
get passed down and where the backwards compatibility logic will reside (this will be covered in greater detail later).

Create a dev cluster using the bigbang branch you created and your package's branch to validate the deployment comes up as expected.

## Package Updates

1. Manually review all network policies that currently exist for a given package. These are typically located in the 
   `/templates/bigbang/networkpolicies` folder, however, some packages have them spread out in other places as well. Delete 
   all network policies that will be replaced by bb-common default policies. If any network policies exist to allow traffic
   for helm tests these can also be deleted as they are already provided by gluon starting in 0.9.0 and later versions.

2. Identify any policies that enable access to the Kubernetes API endpoint and replace them with the [built-in definition](/docs/network-policies#egress-definitions)
   from bb-common after validating they are in fact required.

3. Identify any policies related to allowing traffic from the ingress gateways and delete them. Their creation will be taken
   care of later on in this process.

4. Identify any package specific values that may exist in that package under the `networkPolicies` section and take note of them
   as they will need to be handled later on in the process. At this point it should look like the following:

   ```yaml
   networkPolicies:
     enabled: false
     additionalPolicies: []
   ```

5. Replace any package specific network policies with bb-common generated policies one by one ensuring preferred labels, 
   `app.kubernetes.io/name`, are used when possible. For situations where the same traffic is referenced multiple times, 
   create package level definitions to reduce duplication. All ingress traffic should also reference the service account
   of the workload as this will be used to generate authorization policies. Refer to the examples below for assistance on this portion:

   > **Note**: Some network policies may need to be in the umbrella template level only as a definition vs at the package level. 
   > These rules include policies for egress to SSO, Postgresql, or S3 access to name a few. This gives the ability to be overridden 
   > once globally and passed down into packages for ease of use. See the table below for a list of these global policies.

   | Definition           | Purpose                                                                     |
   | -------------------- | --------------------------------------------------------------------------- |
   | sso                  | Allows egress traffic to SSO server                                         |
   | storage-subnets      | Allows egress traffic to external storage (i.e S3, Azure blob storage, etc) |
   | database-subnets     | Allows egress traffic to external databases                                 |
   | loadbalancer-subnets | Allows ingress traffic from load balancers                                  |

   Refer to the [Network Policy Examples](#network-policy-examples) section for examples if needed.

6. Use the following `helm template` command to verify each network policy renders as expected:

   `helm template <packageName> ./chart -n <packageName> --set networkPolicies.enabled=true | yq eval 'select(.kind == "NetworkPolicy")'`

7. Delete all authorization policies from the package (typically located in the /template/bigbang/istio/authorizationPolicies folder) 
   and overwrite the `istio` section with the following values:

   ```yaml
   istio:
     enabled: false
   
     sidecar:
       enabled: false
       outboundTrafficPolicyMode: "REGISTRY_ONLY"
   
     serviceEntries:
       custom: []
   
     authorizationPolicies:
       enabled: false
       custom: []
   
     # Default peer authentication
     mtls:
       # STRICT = Allow only mutual TLS traffic
       # PERMISSIVE = Allow both plain text and mutual TLS traffic
       mode: STRICT
   ```

8. Use the following `helm template` command to verify all authorization policies render as expected:

   `helm template <packageName> ./chart -n <packageName> --set "networkPolicies.enabled=true,istio.enabled=true,istio.authorizationPolicies.enabled=true,istio.authorizationPolicies.generateFromNetpol=true" | yq eval 'select(.kind == "AuthorizationPolicy")'`
   
   > **Note**: Many packages may have authorization policies that were invalid or unused so they may not match up exactly.

9. Delete the default peer authentication which is typically located in the `templates/bigbang/istio` folder. Some packages may have additional peer authentications so take note of them if they exist
   as they likely are not needed. If no upstream documentation exists supporting the need for them they should be removed.

10. If the package has one or more virtual services they should be deleted along with any service entries. Refer to the following example for guidance on this:
   
   ### Migration Example:
   
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
   
11. Run the following `helm template` commands to validate the virtual service: 

   `helm template <packageName> ./chart -n <packageName> --api-versions networking.istio.io/v1 --set "networkPolicies.enabled=true,istio.enabled=true,istio.authorizationPolicies.enabled=true,istio.authorizationPolicies.generateFromNetpol=true" | yq eval 'select(.kind == "VirtualService")'`

   > **Note**: This same command can be used to validate its associated network and authorization policy is created as expected
   > by changing the filtered `kind` to whichever resource you want to validate.

## Umbrella Template Updates

1. Create a new branch on the bigbang repo called `<packageName>-bb-common` and add the following section to the top of the package's template just under it's first
   `if` condition updating it as needed:

   ```yaml
   {{- /* Create a cleaned copy of package config and merge deprecated paths into current paths */ -}}
   {{- $<packageName>Package := deepCopy .Values.<packageName> -}} # Update the variable to be the name of the package and update the package's path
   {{- if .Values.<packageName>.values -}} # Update this to the package's path
     {{- $cleanedValues := include "mergeLegacyIstioHardenedKeys" (dict "values" .Values.<packageName>.values) | fromYaml -}} # Update this to the package's path
     {{- $<packageName>Package = set $<packageName>Package "values" $cleanedValues -}} # Update to use variable created earlier
   {{- end -}}
   ```

   Update the `package` reference in the `values-secret` include to leverage the newly created variable:

   ```yaml
   {{- include "values-secret" (dict "root" $ "package" $<packageName>Package "name" <packageName> "defaults" (include "bigbang.defaults.<packageName>" .)) }}
   ```

   This section is being used to handle the legacy Istio hardened section such that it works with the newer configuration provided by bb-common. Refer to this [example](https://repo1.dso.mil/big-bang/bigbang/-/blob/3.16.0/chart/templates/minio/values.yaml?ref_type=tags#L2-9).

2. Add a new variable for `istioHardenedEnabled` near the already existing variable of `istioEnabled`updating it with the package name as needed:

   ```yaml
   {{- $istioHardenedEnabled := or (dig "istio" "hardened" "enabled" false .Values.<packageName>.values) (dig "hardened" "enabled" false .Values.istiod.values) }}
   ```

3. Add the following `istio` section referencing the newly created variable:

   ```yaml
   istio:
     enabled: {{ $istioEnabled }}
     hardened:
       enabled: {{ $istioHardenedEnabled }}
   
     sidecar:
       enabled: {{ $istioHardenedEnabled }}
   
     authorizationPolicies:
       enabled: {{ $istioHardenedEnabled }}
       generateFromNetpol: true
   ```

   The `mTLS` section can be omitted as it has already been set to `STRICT` by default at the package level.

4. Copy in the `routes` and `networkPolicies` section from the package level adding in the following into the `networkPolicies section`:

   ```yaml
   networkPolicies:
     enabled: {{ .Values.networkPolicies.enabled }}
     # note: ztunnel does not exist yet, defaulting to false until ambient package is added
     hbonePortInjection:
       enabled: {{ dig "enabled" false (default dict .Values.ztunnel) }}
     egress:
       definitions:
         {{ toYaml .Values.networkPolicies.egress.definitions | nindent 6 }}
     ingress:
       definitions:
         {{ toYaml .Values.networkPolicies.ingress.definitions | nindent 6 }}
   ```

   The `hbonePortInjection` is needed for when ambient rolls out as it will allow other packages to still communicate as needed even when
   operating in a different mode. 
   
   The `definitions` for `ingress` and `egress` should always be passed down as shown above even if the package doesn't leverage any of them.
   
   Make sure to enable/disable any network policies at this level where it makes sense (i.e. `{{ .Values.monitoring.enabled }}`).

5. Create an additional file in the templates folder called `_bb-common-migrations.tpl` and populate it with the following data:

   ```yaml
   {{- define "bigbang.<packageName>.bb-common-migrations" }}
   {{/* TODO: Remove this migration template for bb 4.0 */}}
   {{- end }}
   ```

   Update the `defaults` reference in the `values-secret` include to merge this file together with the package's default values:

   ```yaml
   "defaults" (merge (include "bigbang.headlamp.bb-common-migrations" . | fromYaml) (include "bigbang.defaults.<packageName>" . | fromYaml) | toYaml)
   ```

   This is where the older values like `controlPlaneCidr`, `vpcCidr`, and any other package specific values that may have existed under the
   `networkPolicies` section of the package will be referenced.

   > **Note**: This step can be skipped if no backward compatibility logic is required for a given package.

6. Review the test-values.yaml file in the bigbang repo and remove any values that are no longer needed. There should be no need for additional 
   authorization policies in the test-values.yaml file and test related service entries can be moved into the `routes.outbound` section where it can
   be enabled conditionally.

For a full example of this process please refer to (https://repo1.dso.mil/big-bang/bigbang/-/tree/3.17.0/chart/templates/headlamp?ref_type=tags).

## Final Steps

Once all of the above steps are completed, stand up a development cluster using the big bang branch created in the last step and the package's
branch created in the step prior to that. Validate all connectivity per the packages development maintenance documentation (i.e. Verify service monitor,
validate SSO authentication if applicable, etc). Check the pod logs for any errors that may be related to connectivity and check the `istio-proxy`
container logs.

The following table shows the most common errors along with their cause:

| Error Message       | Common Cause                                  |
| ------------------- | --------------------------------------------- |
| Connection Refused  | Missing or misconfigured network policy       |
| RBAC: access denied | Missing or misconfigured authorization policy |
| BlackholeCluster    | Missing service entry                         |

The following command can also be used after some quick modifications to easily draw out this information from the `istio-proxy` container logs:

```bash
export NS=argocd && for pod in $(kubectl get pods -n $NS -o name); do kubectl logs -n $NS $pod -c istio-proxy 2>/dev/null | grep -H --label="$pod" BlackHoleCluster; done
```

For issues where the resources don't seem to be getting populated as expected please refer to [this section](/docs/network-policies?ref_type=heads#troubleshooting).

The Kiali UI is another great resource to troubleshoot any issues as it provides the ability to review network traffic and its Istio Config section can
also be very handy in spotting any misconfigurations in Istio resources.

At this point it is recommended to validate the updates as an upgrade as well where you can also gather all evidence in the form of logs and screenshots
to provide in the package's merge request.

## Appendix

### Network Policy Examples

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

> **Note**: If the user-provided CIDR **is** the excluded CIDR (e.g., wanting to
> explicitly allow access to just the metadata endpoint), the framework will not
> apply the exception.   

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
            my-web-svc-account@frontend/web: true # Pod specific traffic should include service account as well
            admin/*: true # Any pod from admin namespace
      api:9090:
        from:
          k8s:
            monitoring-monitoring-kube-prometheus@monitoring/prometheus: true
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