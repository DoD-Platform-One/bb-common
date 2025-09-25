#!/usr/bin/env bats

# Test configuration
export TEST_REPO="https://repo1.dso.mil/big-bang/product/packages/kiali.git"
export BRANCH="2.15.0-bb.0" # this is pinned so tests are stable
export SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

setup() {
    # Create unique test directory for each test
    export TEST_DIR="/tmp/schema-test-bats-$$-${BATS_TEST_NUMBER}"
    mkdir -p "${TEST_DIR}"
}

teardown() {
    # Cleanup test directory
    if [[ -d "${TEST_DIR}" ]]; then
        rm -rf "${TEST_DIR}"
    fi
}

@test "schema.sh dependencies are available" {
    run command -v yq
    [ "$status" -eq 0 ]

    run command -v helm
    [ "$status" -eq 0 ]

    run command -v curl
    [ "$status" -eq 0 ]
}

@test "schema.sh runs successfully on kiali chart" {
    cd "${TEST_DIR}"
    git clone --branch "${BRANCH}" "${TEST_REPO}" kiali

    # Run schema.sh script
    run "${SCRIPT_DIR}/schema.sh" kiali/chart
    [ "$status" -eq 0 ]

    # Validate schema syntax
    run yq e '.' kiali/chart/values.schema.json
    [ "$status" -eq 0 ]

    # Check if networkPolicies property exists in schema
    run yq e '.properties.networkPolicies' kiali/chart/values.schema.json
    [ "$status" -eq 0 ]

    # Check if routes property exists in schema
    run yq e '.properties.routes' kiali/chart/values.schema.json
    [ "$status" -eq 0 ]

    # Check if updated schema for routes is exactly the same as bb-common schema
    # Get the bb-common version that was actually used by the script
    bb_common_version=$(yq e '.dependencies[] | select(.name == "bb-common") | .version' kiali/chart/Chart.lock)

    # Download the same version that the script used for comparison
    curl -s -f "https://repo1.dso.mil/big-bang/product/packages/bb-common/-/raw/${bb_common_version}/chart/values.schema.json" > "${TEST_DIR}/bb-common-schema.json"

    # Extract routes property from both schemas and compare
    yq e '.properties.routes' kiali/chart/values.schema.json > "${TEST_DIR}/kiali-routes.json"
    yq e '.properties.routes' "${TEST_DIR}/bb-common-schema.json" > "${TEST_DIR}/bb-common-routes.json"

    # Compare the routes properties
    run diff "${TEST_DIR}/kiali-routes.json" "${TEST_DIR}/bb-common-routes.json"
    [ "$status" -eq 0 ]

    # Check if $defs section exists
    run yq e '.["$defs"]' kiali/chart/values.schema.json
    [ "$status" -eq 0 ]
}

@test "schema.sh fails when no existing schema file" {
    cd "${TEST_DIR}"
    git clone --branch "${BRANCH}" "${TEST_REPO}" kiali

    # Remove existing schema
    rm kiali/chart/values.schema.json

    # Run schema.sh script - should fail
    run "${SCRIPT_DIR}/schema.sh" kiali/chart
    [ "$status" -eq 1 ]
    [[ "$output" == *"Chart must have an existing values.schema.json file"* ]]
}

@test "schema.sh exits early for subchart mode" {
    cd "${TEST_DIR}"
    git clone --branch "${BRANCH}" "${TEST_REPO}" kiali

    # Add bb-common as subchart key to values.yaml (overwrite to ensure clean state)
    cat > kiali/chart/values.yaml << 'EOF'
domain: bigbang.dev
bb-common:
  enabled: true
  networkPolicies:
    enabled: true
EOF

    # Run schema.sh script - should exit early
    run "${SCRIPT_DIR}/schema.sh" kiali/chart
    [ "$status" -eq 0 ]
    [[ "$output" == *"bb-common is being used as a subchart"* ]]
}

@test "schema.sh fails with invalid chart directory" {
    run "${SCRIPT_DIR}/schema.sh" /nonexistent/path
    [ "$status" -eq 1 ]
    [[ "$output" == *"Could not find Chart.yaml"* ]]
}
