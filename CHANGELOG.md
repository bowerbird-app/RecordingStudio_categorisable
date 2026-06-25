# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-05-12

### Added
- Renamed the engine surface from the template namespace to `recording_studio_categorisable`
- Added Recording Studio-backed category group and category item recordables with mounted management UI
- Added explicit categorisable registration APIs and usage counting based on registered category fields
- Added dummy app page editing flow with single-select and multi-select category assignments
- Added root engine tests plus dummy app integration coverage for usage-aware destructive actions and page revisions

## [0.1.1] - 2026-04-28

### Changed
- Bumped the dummy app FlatPack dependency from `0.1.2` to `0.1.33` and pinned it by tag in `test/dummy/Gemfile`

## [0.1.0] - 2025-12-04

### Added
- Initial release
- Rails mountable engine structure
- PostgreSQL with UUID primary keys support
- TailwindCSS v4 integration
- GitHub Codespaces devcontainer configuration
- Docker Compose setup with PostgreSQL and Redis
- Install generator for host applications
- Comprehensive README and documentation
- Basic test suite with Minitest

[Unreleased]: https://github.com/bowerbird-app/recording_studio_categorisable/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/bowerbird-app/recording_studio_categorisable/releases/tag/v0.2.0
[0.1.1]: https://github.com/bowerbird-app/recording_studio_categorisable/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/recording_studio_categorisable/releases/tag/v0.1.0
