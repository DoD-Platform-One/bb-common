# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [0.12.2] - 2026-1-06

### Added

- Added `routes.inbound.<route>.containerPort` to support service pod port discrepency

## [0.12.1] - 2025-12-30

### Fixed

- Fixed default ambient netpol logic so it doesn't error out when `istio` section does not exist in chart

## [0.12.0] - 2025-12-18

### Added

- Added initial support for outbound routing with `ServiceEntry` resource generation

## [0.11.3] - 2025-12-16

### Fixed

- Updated CIDR exclusion logic to handle cases where the CIDR is identical to the exclusion

## [0.11.2] - 2025-12-12

### Fixed

- Updated hbone port injection to skip netpol rules without a k8s selector

## [0.11.1] - 2025-12-08

### Fixed

- Fixed naming conventions of authorization policies to avoid invalid characters and make naming more consistent
- Updated associated documentation and added tests to validate authorization policy naming and rules

---
## [0.11.0] - 2025-11-07

### Fixed

- Added ambient specific network policies and associated tests and schema updates
- Added ability to inject TCP port 15008 into network policies in support of ambient communication requirements

## [0.10.0] - 2025-10-24

### Fixed

- Remove istio.hardened flag in favor of explicit sidecar configuration.
- Move customAuthorizationPolicies and customServiceEntries to `istio.authorizationPolicies.custom` and `istio.serviceEntries.custom`
- Ensure global enabled flags for NetworkPolicies and AuthorizationPolicies are respected by routes

## [0.9.1] - 2025-10-22

### Fixed

- Handle when Istio configuration is not present

## [0.9.0] - 2025-10-20

### Added

- Added default authorization policies, as well as enhanced authorization policy generation
- Handle Istio package configuration (Sidecar / PeerAuthentication)

## [0.8.3] - 2025-10-17

### Fixed

- Fixed issue where custom label selectors for NetworkPolicies were being serialized into annotations and generated invalid resources

## [0.8.2] - 2025-09-30

### Changed

- Updated routes NetworkPolicy selectors to use `kubernetes.io/metadata.name` for namespace selector and `app.kubernetes.io/name` for pod selector to align with Kubernetes standards

## [0.8.1] - 2025-09-15

### Added

- Prevent routes resources (VirtualServices/AuthorizationPolicy) from being created if Istio is not available.

## [0.8.0] - 2025-09-15

### Added

- Added support for VirtualService generated resources
  
## [0.7.1] - 2025-09-15

### Changed

- Fixed the behavior of egress netpols when more than one policy is specified under the same wildcard (`"*"`) local key

## [0.7.0] - 2025-09-10

### Added

- Configured the default egress policies to be available during helm hook phases
- Added documentation about the self-test feature
- Updated the self-test feature to make it more versatile and usable in more situations

## [0.6.1] - 2025-09-04

### Changed

- Changed the `istiod` selector back to `app: istiod` due to [issue with vpc-cni](https://github.com/aws/aws-network-policy-agent/issues/460)

## [0.6.0] - 2025-09-04

### Added

- Added the ability to set custom labels and annotations for generated resources

## [0.5.2] - 2025-08-22

### Added

- Added the ability to test individual templates in isolation

## [0.5.1] - 2025-08-14

### Added

- Added default ingress policy to permit prometheus sidecar scraping

## [0.5.0] - 2025-08-13

### Added

- Added a port lookup to the default `kubeAPI` egress definition in the `NetworkPolicy` implementation

## [0.4.3] - 2025-08-07

### Changed

- Removed 15014 port as that is only required for apps that monitor istio
- Updated unit test to reflect changes

## [0.4.2] - 2025-08-06

### Changed

- Updated istiod egress default rule to include port 15014 and updated pod selector label used
- Updated unit test to reflect changes

## [0.4.1] - 2025-07-30

### Changed

- Updated JSON Schema to be compliant with https://json-schema.org/draft/2020-12/schema

## [0.4.0] - 2025-07-30

### Changed

- Refactored the network-policy implementation to use shorthand pattern

### Added

- Authorization Policy generation from netpol shorthand

## [0.3.1] - 2025-07-14

### Changed

- Separated helpers into sub-directories

## [0.3.0] - 2025-07-11

### Changed

- Updated istio ingress gateway network policy generation to support label selectors and multiple policies

## [0.2.0] - 2025-07-11

### Added

- Added support for templating values in `package` policies

## [0.1.5] - 2025-07-10

### Added

- Added support for targeting specific pods for KubeAPI network policy

## [0.1.4] - 2025-06-27

### Added

- Added network policies for minio and updated documentation

## [0.1.3] - 2025-06-27

### Added

- Fixed bug in new netpols where delimiter was missing
- Added migration documentation

## [0.1.2] - 2025-06-23

### Added

- Added two new network policies and corresponding tests
- Updated existing network policy and test
- Added missing tests
- Updated values.yaml to include defaults that are common across packages

## [0.1.1] - 2025-06-12

### Added

- Added unittests for pipeline
- Converted chart from library to application

## [0.1.0] - 2025-05-28

### Added

- Initial templating for network policies
- Documentation on new library chart
