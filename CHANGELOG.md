# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
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
