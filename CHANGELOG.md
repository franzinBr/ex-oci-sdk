# Changelog
All notable changes to ExOciSdk will be documented in this file.
## [0.2.2] - W.I.P

### Added
- Support the native JSON module for Elixir >= 1.18.0
- `ExOciSdk.Config.from_runtime!/0` to create oci configuration from runtime envs

### Changed
- Changes the minimum elixir version from 1.18 to 1.15

## [0.2.1] - 2025-02-16

### Fixed
- Bug in `ExOciSdk.Config.from_file!/1` where path expansion (`~`, `../`) wasn't working correctly

## [0.2.0] - 2025-02-03
### Added
- [`QueueAdminClient`](queue_admin_client.md) module for queue administration operations
- header extraction mechanism for metadata in core response policy

### Fixed
- bug handling responses with different content-type header cases

## [0.1.0] - 2025-01-29
### Added
- Core SDK functionality
- [`QueueClient`](queue_client.md) module for queue operations
