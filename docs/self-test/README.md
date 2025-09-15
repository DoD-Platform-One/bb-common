# SelfTest Framework

<!--toc:start-->

- [SelfTest Framework](#selftest-framework)
  - [Overview](#overview)
  - [Configuration](#configuration)
    - [Basic Usage](#basic-usage)
    - [Advanced Usage](#advanced-usage)
    - [Configuration Schema](#configuration-schema)
  - [Implementation Details](#implementation-details)
    - [Output Format](#output-format)
  - [Usage Examples](#usage-examples)
    - [Testing String Output Templates](#testing-string-output-templates)
    - [Testing YAML Output Templates](#testing-yaml-output-templates)
  - [Writing Tests](#writing-tests)
    - [Test File Structure](#test-file-structure)
    - [Assertion Patterns](#assertion-patterns)
      - [String Results](#string-results)
      - [YAML Array Results](#yaml-array-results)
  - [Best Practices](#best-practices)
    - [Template Testing](#template-testing)
    - [Result Parsing](#result-parsing)
    - [File Organization](#file-organization)
  - [Extending the Framework](#extending-the-framework)

<!--toc:end-->

The `selfTest` framework provides a standardized way to unit test Helm template
functions within the bb-common chart. It enables developers to validate template
logic by invoking templates with test data and capturing their output for
assertion-based testing.

## Overview

The selfTest system works by:

1. Reading test configurations from `Values.selfTest`
2. Executing specified Helm templates with provided arguments
3. Capturing template output and wrapping it in a `TestResult` custom resource
4. Generating test manifests that can be validated using helm-unittest

## Configuration

### Basic Usage

```yaml
selfTest:
  "template-name":
    - arg1
    - arg2
    - arg3
```

### Advanced Usage

```yaml
selfTest:
  "template-name":
    args:
      - arg1
      - arg2
    resultIsYaml: true # Parse result as YAML array
```

### Configuration Schema

- **Template Name** (key): The name of the Helm template to test (e.g.,
  `bb-common.utils.as-hooks`)
- **Simple Form**: Direct arguments passed as an array or single value
- **Advanced Form**: Object with the following properties:
  - `args`: Arguments to pass to the template function
  - `resultIsYaml`: Boolean flag indicating whether the template result should
    be parsed as YAML (default: false)

## Implementation Details

The selfTest functionality is implemented in
`/chart/templates/utils/self-test.yaml`:

```yaml
{{- define "bb-common.utils.self-test" }}
  {{- range $templateName, $config := .Values.selfTest | default dict }}
    # Creates TestResult custom resource for each test
    apiVersion: testing.bb-common.bigbang.dev/v1
    kind: TestResult
    metadata:
      name: {{ $templateName }}
    args: {{ $args }}
    result: {{ template output }}
  {{- end }}
{{- end }}
```

### Output Format

Each test generates a `TestResult` resource with:

- `apiVersion`: `testing.bb-common.bigbang.dev/v1`
- `kind`: `TestResult`
- `metadata.name`: The template name being tested
- `args`: The arguments passed to the template
- `result`: The template output (string or parsed YAML)

## Usage Examples

### Testing String Output Templates

```yaml
# Test a template that returns a string
selfTest:
  "bb-common.network-policies.name-ports":
    - - port: 80
      - port: 443
    - false
```

Expected result: `"ports-80-443"`

### Testing YAML Output Templates

```yaml
# Test a template that returns YAML resources
selfTest:
  "bb-common.utils.as-hooks":
    resultIsYaml: true
    args:
      - - apiVersion: networking.k8s.io/v1
          kind: NetworkPolicy
          metadata:
            name: test-policy
          spec:
            podSelector: {}
      - - pre-install
        - pre-upgrade
      - -5
      - - hook-succeeded
```

Expected result: Array of Kubernetes resources with hook annotations

## Writing Tests

### Test File Structure

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/helm-unittest/helm-unittest/main/schema/helm-testsuite.json
suite: template-name
templates:
  - templates/utils/self-test.yaml
tests:
  - it: test description
    set:
      selfTest:
        "template-name":
    # test configuration
    asserts:
      - equal:
          path: result
          value: expected-value
```

### Assertion Patterns

#### String Results

```yaml
asserts:
  - equal:
      path: result
      value: "expected-string"
```

#### YAML Array Results

```yaml
asserts:
  - equal:
      path: result[0].metadata.name
      value: expected-name
  - equal:
      path: result[0].spec.podSelector
      value: {}
```

## Best Practices

### Template Testing

1. **Test Edge Cases**: Include tests for empty inputs, single items, and
   multiple items
2. **Validate Structure**: For YAML results, test both structure and values
3. **Use Descriptive Names**: Test names should clearly describe the scenario
   being tested
4. **Test Error Conditions**: Verify templates handle invalid inputs gracefully

### Result Parsing

1. **Use `resultIsYaml: true`** for templates that return Kubernetes resources
   or YAML arrays
2. **Keep Arguments Simple**: Use basic data types in test arguments when
   possible
3. **Group Related Tests**: Organize tests by template functionality

### File Organization

- Place test files in `/chart/tests/` directory
- Use naming convention: `{template-name-minus-bb-common}_test.yaml`
- Include yaml-language-server schema for IDE support

## Extending the Framework

To add selfTest support to a new template:

1. **Create the template** following bb-common naming conventions
2. **Add test configuration** to a test file in `/chart/tests/`
3. **Use the selfTest framework** by setting `Values.selfTest` in your test
4. **Write assertions** to validate the template output

The selfTest framework automatically handles template invocation and result
capture, allowing you to focus on writing meaningful test cases.
