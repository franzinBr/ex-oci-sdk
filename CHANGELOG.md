# Changelog
All notable changes to ExOciSdk will be documented in this file.

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
