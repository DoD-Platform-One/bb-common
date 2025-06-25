## Purpose

The purpose of this chart is to reduce the amount of code duplication that exists across all packages.  Additionally, it should allow us to more quickly update resources that are shared and onboard new packages quickly.

### bb-common Library Chart Integration

In order to make use of this chart, simply add the following to your package's chart.yaml:

```
dependencies:
  - name: bb-common
    version: "0.1.0"
    repository: "oci://registry1.dso.mil/bigbang"
```

> [!NOTE]
> Please be sure to update the version with the most current version available.

Once the file has been added, change to the `chart` directory for your package and run the following command:

`helm dep update`

The final step for integrating this library chart is to create a file called common.yaml under your templates/bigbang folder with the following contents:

```
{{- if .Values.networkPolicies.enabled }}
{{- include "bb-common.netpols.all" . }}
{{- end }}
```

The package should now be using all shared network policies and will now have the ability to use shorthand network policies for any package specific policies.

### Testing

This project is using the unittests plugin for helm which can be installed by following the documentation [here](https://github.com/helm-unittest/helm-unittest?tab=readme-ov-file#install).

In order to run the tests execute the following command:

`cd chart && helm unittest .`

####  Future State

In the future the following items will likely also be integrated into this library chart:

- Authorization Policies
- Service Entries
- Peer Authentications
- Vritual Services

The end goal of this library will be to have all values at the package level under a `bigbang` enabling any package to simply override the defaults set forth in the values.yaml file.  In the interim, while the package is being improved and iterated upon packages will simply use the templated definitions.