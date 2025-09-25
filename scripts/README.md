# BB-Common Schema Management Scripts

This directory contains scripts for managing JSON schema updates in charts that use bb-common functionality.

## schema.sh

Automatically updates JSON schemas for charts that use bb-common templates. This script ensures that charts have the correct schema definitions for bb-common features like network policies and routes.

### Prerequisites

- `yq` (YAML processor)
- `helm` (Helm CLI)
- `curl` (for downloading schemas)

### Usage

```bash
./scripts/schema.sh [CHART_DIRECTORY]
```

**Parameters:**
- `CHART_DIRECTORY` (optional): Path to the chart directory. If not specified, the script will auto-detect by looking for `Chart.yaml` in:
  - Current directory (`.`)
  - `./chart` subdirectory

### What the Script Does

1. **Validates Dependencies**: Checks that required tools are installed
2. **Locates Chart**: Finds and validates the Helm chart directory
3. **Updates Dependencies**: Runs `helm dependency update` if needed
4. **Detects bb-common Usage**: Determines how bb-common is being used:
   - **Subchart mode**: bb-common is configured as a subchart with its own values
   - **Template mode**: Chart uses bb-common templates directly
5. **Schema Updates**: For template mode, automatically updates schemas based on usage:
   - **Network Policies**: If chart uses `bb-common.network-policies.render`
   - **Routes**: If chart uses `bb-common.routes.render`

### Schema Update Process

When bb-common templates are detected, the script:

1. **Downloads** the bb-common schema from the git repository matching the version in `Chart.lock`
2. **Merges** the relevant schema sections:
   - Copies `networkPolicies` properties from bb-common
   - Copies `routes` properties from bb-common
   - Merges `$defs` definitions (bb-common definitions take precedence)
3. **Updates** the chart's `values.schema.json` with merged content

### Examples

#### Basic Usage

```bash
# Run from bb-common root directory
./scripts/schema.sh /path/to/my-chart

# Auto-detect chart in current directory
cd /path/to/my-chart
/path/to/bb-common/scripts/schema.sh

# Run directly from remote repository (curl pipe to bash)
curl -sSL https://repo1.dso.mil/big-bang/product/packages/bb-common/-/raw/main/scripts/schema.sh | bash -s /path/to/my-chart

# Or with auto-detection
cd /path/to/my-chart
curl -sSL https://repo1.dso.mil/big-bang/product/packages/bb-common/-/raw/main/scripts/schema.sh | bash

# Use 'main' for latest development version (not recommended for production)
curl -sSL https://repo1.dso.mil/big-bang/product/packages/bb-common/-/raw/main/scripts/schema.sh | bash -s /path/to/my-chart
```

#### Typical Output

```bash
Updating helm dependencies: Chart.yaml has been updated more recently than Chart.lock
[helm dependency update output...]
Updating networkPolicies schema.
Updating routes schema.
Fetching bb-common schema version 0.5.1...
Successfully downloaded bb-common schema
Successfully updated networkPolicies schema in /path/to/chart/values.schema.json
Successfully updated routes schema in /path/to/chart/values.schema.json
```

### When to Use

- **Development**: Ensure your chart has up-to-date schema definitions
- **Chart Maintenance**: Keep schemas synchronized with bb-common capabilities

### Chart Requirements

For the script to work, your chart must:

1. **Include bb-common as dependency** in `Chart.yaml`:

   ```yaml
   dependencies:
     - name: bb-common
       version: "0.7.0"
       repository: "oci://registry1.dso.mil/bigbang"
   ```

2. **Use bb-common templates** in your chart templates:

   ```yaml
   # For network policies
   {{- include "bb-common.network-policies.render" . }}

   # For routes
   {{- include "bb-common.routes.render" . }}
   ```

### Subchart vs Template Mode

#### Template Mode (Schema Updates Applied)

```yaml
# Chart.yaml
dependencies:
  - name: bb-common
    version: "0.7.0"
    repository: "oci://registry1.dso.mil/bigbang"

# values.yaml - No bb-common key
domain: example.com
networkPolicies:
  enabled: true

# templates/network-policies.yaml
{{- include "bb-common.network-policies.render" . }}

# templates/routes.yaml
{{- include "bb-common.routes.render" . }}
```

#### Subchart Mode (No Schema Updates as the schema is enforced by Helm natively)

```yaml
# Chart.yaml - same as above

# values.yaml - bb-common configured as subchart
domain: example.com
bb-common:
  networkPolicies:
    enabled: true
```

### Testing

The script includes comprehensive test coverage using the bats framework:

```bash
# Run the full test suite
bats scripts/tests/test-schema.bats

# Run with verbose output
bats scripts/tests/test-schema.bats --show-output-of-passing-tests
```

The tests validate:

- Script functionality and error handling
- Schema merging and validation
- Subchart vs template mode detection
- Integration with real charts (using kiali as test case)