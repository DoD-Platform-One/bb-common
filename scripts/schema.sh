#!/usr/bin/env bash

# BB-Common Schema Update Script
# Automatically updates JSON schemas for charts that use bb-common templates
# This ensures charts have correct schema definitions for bb-common features

# Check required dependencies
dependencies=(
  yq
  helm
  curl
)

for cmd in "${dependencies[@]}"; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "This script requires these commands: ${dependencies[*]}"
    echo "Make sure you have them installed and available in your PATH and try again."
    exit 1
  fi
done

# Function to merge $defs definitions from bb-common schema (bb-common takes precedence)
merge_defs() {
  local working_schema="$1"
  local bb_common_schema="$2"

  yq eval-all '
    select(fileIndex == 0) as $current |
    select(fileIndex == 1) as $bb |
    $current | .["$defs"] = (.["$defs"] // {}) * ($bb.["$defs"] // {})
  ' "${working_schema}" "${bb_common_schema}" -i "${working_schema}"
}

# Function to merge a property from bb-common schema
merge_property() {
  local working_schema="$1"
  local bb_common_schema="$2"
  local property_name="$3"

  yq eval-all "
    select(fileIndex == 0) as \$current |
    select(fileIndex == 1) as \$bb |
    \$current | .properties.${property_name} = \$bb.properties.${property_name}
  " "${working_schema}" "${bb_common_schema}" -i "${working_schema}"
}

# Locate chart directory
declare chart_dir

if [ -n "${1}" ]; then
  # Chart directory provided as argument
  if [ ! -f "${1}/Chart.yaml" ]; then
    echo "Error: Could not find Chart.yaml in ${1}"
    exit 1
  fi
  chart_dir="${1}"
elif [ -f "./Chart.yaml" ]; then
  # Chart.yaml in current directory
  chart_dir="."
elif [ -f "./chart/Chart.yaml" ]; then
  # Chart.yaml in chart subdirectory
  chart_dir="./chart"
fi

if [ ! -f "${chart_dir}/Chart.yaml" ]; then
  echo "Error: Could not find Chart.yaml in ${chart_dir}"
  exit 1
fi

# Update helm dependencies to ensure Chart.lock is current
echo "Updating helm dependencies..."
helm dependency update "${chart_dir}"

# Extract bb-common version
if ! bb_common_version=$(yq e '.dependencies[] | select(.name == "bb-common") | .version' "${chart_dir}/Chart.lock"); then
  echo "Error: Could not find bb-common in ${chart_dir}/Chart.lock. Add it to your Chart.yaml"
  exit 1
fi

# Extract bb-common alias (if any)
bb_common_alias=$(yq e '.dependencies[] | select(.name == "bb-common") | .alias' "${chart_dir}/Chart.lock")
if [ -z "${bb_common_alias}" ] || [ "${bb_common_alias}" == "null" ]; then
  bb_common_alias="bb-common"
fi

# Detect if bb-common is used as subchart or template mode
if [ -f "${chart_dir}/values.yaml" ]; then
  # Check if bb-common (or its alias) exists as a top-level key in values.yaml
  if yq e "has(\"${bb_common_alias}\")" "${chart_dir}/values.yaml" 2>/dev/null | grep -q "true"; then
    echo "bb-common is being used as a subchart. No schema update required."
    exit 0
  fi
fi

# Check which bb-common render templates are being used
is_using_network_policies=false
is_using_routes=false

if grep -r -E 'bb-common\.network-policies\.render' . >/dev/null 2>&1; then
  is_using_network_policies=true
fi

if grep -r -E 'bb-common\.routes\.render' . >/dev/null 2>&1; then
  is_using_routes=true
fi

# Update schemas if any bb-common templates are used
if $is_using_network_policies || $is_using_routes; then
  echo "Updating bb-common schema."

  # Create temp directory for schema operations
  temp_dir=$(mktemp -d)
  bb_common_schema="${temp_dir}/bb-common-schema.json"
  current_schema="${chart_dir}/values.schema.json"

  # Fetch bb-common schema from git repository
  bb_common_schema_url="https://repo1.dso.mil/big-bang/product/packages/bb-common/-/raw/${bb_common_version}/chart/values.schema.json"

  echo "Fetching bb-common schema version ${bb_common_version}..."
  if curl -s -f "${bb_common_schema_url}" > "${bb_common_schema}"; then
    echo "Successfully downloaded bb-common schema"

    # Verify chart has existing schema file
    if [ ! -f "${current_schema}" ]; then
      echo "Error: ${current_schema} not found. Chart must have an existing values.schema.json file."
      exit 1
    fi

    # Start with current schema and merge bb-common schemas step by step
    cp "${current_schema}" "${temp_dir}/working-schema.json"

    # Merge schemas using dedicated functions
    merge_defs "${temp_dir}/working-schema.json" "${bb_common_schema}"

    if $is_using_network_policies; then
      echo "Updating networkPolicies schema."
      merge_property "${temp_dir}/working-schema.json" "${bb_common_schema}" "networkPolicies"
    fi

    if $is_using_routes; then
      echo "Updating routes schema."
      merge_property "${temp_dir}/working-schema.json" "${bb_common_schema}" "routes"
    fi

    # Replace current schema with merged version
    mv "${temp_dir}/working-schema.json" "${current_schema}"
    echo "Successfully updated bb-common schema in ${current_schema}"
  else
    echo "Error: Failed to fetch bb-common schema from ${bb_common_schema_url}"
    echo "Please check the version ${bb_common_version} and network connectivity"
    exit 1
  fi

  # Clean up temporary directory
  rm -rf "${temp_dir}"
fi