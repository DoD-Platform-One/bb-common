## Migrating to bb-common

Prior to performing any of the migrations below please make sure you have followed the steps on integrating the bb-common chart found [here](../README.md#bb-common-library-chart-integration).

### Migrating Network Policies

The following steps are general guidelines to follow to ensure a smooth transition from network policies inside a package to the ones provided by bb-common.

1. Review all existing network policies for the package being migrated to bb-common.  The `helm template` command as shown below can be used to output all resulting network policies to a yaml file that can be used for comparison at the end:

```
helm template chart -n kiali --set networkPolicies.enabled=true --set sso.enabled=true | yq eval 'select(.kind == "NetworkPolicy")' > ../original_policies.yaml
```

> [!NOTE]
> Additional settings may need to be set based on the package (i.e. sso.enabled, etc).

2. Delete all network policies from your package.

3. Add a top level key to your values.yaml called `tracing.enabled` and default it to whatever makes sense for the package.  Previously, the network policy that allows egress traffic from a given package to Tempo is always enabled even if Tempo is disabled.  This new key will be used to ensure it only gets deployed when Tempo is also deployed.

4. Update the `networkPolicies` section under your values.yaml file to look like the following:

```
networkPolicies:
  enabled: true
  ingressLabels:
    app: istio-ingressgateway
    istio: ingressgateway
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
    dynamic:
      enabled: true
      ingress:
        kiali:
        - ports:
          port: 20001
          protocol: TCP
      metricsPorts:
      - port: 1234
        protocol: TCP
      ssoCidrs:
      - 0.0.0.0/0
      databaseCidrs:
      - 10.0.0.0/8
      - 172.16.0.0/12
      - 192.168.0.0/16
  package:  
  additionalPolicies: []
```

If your package does not need access to the Kube API, you can set the `networkPolicies.bundled.kubeApiAccess.enabled` key to false and remove the `controlPlaneCidrs` key underneath it. The `ingress`, `metricsPorts`, `ssoCidrs`, and `databaseCidrs` can also be removed if the package has no ingress, no metric ports for monitoring to scrape, no sso functionality, or no database connectivity respectively.

5. Update the `networkPolicies.package` section in the values.yaml to add any package specific network policies.  Refer to [this documentation](../docs/networkPolicies.md#networkpoliciespackage) on guidance for the method to use for this portion and further instructions on how to implement them.

6. If the package does not have a defined schema this step can be skipped; Otherwise, paste in the following snippets into the appropriate location to ensure the schema reflects the additional values:

**New section for tracing key (Tempo)**

```
    "tracing": {
      "type": "object",
      "properties": {
        "enabled": { "type": "boolean" }
      },
      "additionalProperties": false
    },
```

**New section under the networkPolicies key**

```
        "bundled": {
          "type": "object",
          "properties": {
            "base": {
              "type": "object",
              "properties": {
                "enabled": {"type": "boolean"}
              },
              "additionalProperties": false
            },
            "conditional": {
              "type": "object",
              "properties": {
                "enabled": {"type": "boolean"}
              },
              "additionalProperties": false
            },
            "kubeApiAccess": {
              "type": "object",
              "properties": {
                "enabled": {"type": "boolean"},
                "controlPlaneCidrs": {"type": "array"}
              },
              "additionalProperties": false
            },
            "dynamic": {
              "type": "object",
              "properties": {
                "enabled": {"type": "boolean"},
                "ingress": {"type": "array"},
                "metricsPorts": {"type": "array"},
                "databaseCidrs": {"type": "array"},
                "ssoCidrs": {"type": "array"}
              },
              "additionalProperties": false
            }
          }
        },
        "package": {
          "type": "object"
        },
        "additionalPolicies": {
          "type": "array",
          "items": { "type": "object" }
        },
```

7. With the above changes in place, run the following `helm template` command (with any specific settings enabled) and compare the results to the output from the first step to validate all network policies that should be deployed are generated:

```
helm template chart -n kiali --set networkPolicies.enabled=true --set sso.enabled=true --set monitoring.enabled=true --set tracing.enabled=true | yq eval 'select(.kind == "NetworkPolicy")' > ../updated_policies.yaml
```

> [!NOTE]
> The network policy that allows traffic to PostgreSQL should only be deployed if local database is NOT used so be sure to set the values accordingly in order to validate.  Additionally, some network policies have been combined (i.e. intra-namespace ingress and intra-namespace egress have been combined) so review all policies carefully.

8. Push all changes up to git and deploy a development cluster using the new branch to test/validate.

9. Once the package branch is pushed into main, checkout the Big Bang branch to update the packages version, and make the following changes to the umbrella template for the package:

```
tracing:
  enabled: {{ .Values.tempo.enabled }}
```

If the package requires access to Kubernetes API, the following change will also need to be made:

```
networkPolicies:
  bundled:
    kubeApiAccess:
      controlPlaneCidrs:
      - {{ .Values.networkPolicies.controlPlaneCidr }}
```

If there are package specific network policies that should be enabled or disabled based on other packages being enabled, this should be handled here as well.

Once the above MR is merged into the Big Bang repository the migration is complete!

The following MR's for Kiali and its associated Big Bang MR can be reviewed as a working example of the above steps:

[Kiali Package MR](https://repo1.dso.mil/big-bang/product/packages/kiali/-/merge_requests/314/diffs)

[Kiali Umbrella Template MR](https://repo1.dso.mil/big-bang/bigbang/-/merge_requests/6499/diffs)