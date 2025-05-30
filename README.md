## Purpose

The purpose of this library chart is to reduce the amount of code duplication that exists across all packages.  Additionally, it should allow us to more quickly update resources that are shared and onboard new packages quickly.

### bb-common Library Chart Integration

In order to make use of this library chart, simply add the following to your package's chart.yaml:

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

The final step for integrating this library chart is to create a directory called `common` under your templates folder, and then create a file called `bigbang.yaml` with the following contents:

```
{{- include "bb-common.netpols.all" . }}
```

The package should now be using all shared network policies and will now have the ability to use shorthand network policies for any package specific policies.

####  Future State

In the future the following items will likely also be integrated into this library chart:

- Authorization Policies
- Service Entries
- Peer Authentications