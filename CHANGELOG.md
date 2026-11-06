# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2026-11-06

### Security
- Lockfile-only bump to Rails 8.1.4.1 with rack >= 3.2.8, nokogiri >= 1.19.5, loofah >= 2.25.3, rails-html-sanitizer >= 1.7.2, and net-ssh >= 7.3.5 (dummy)

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

[Unreleased]: https://github.com/bowerbird-app/gem_template/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/bowerbird-app/gem_template/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/gem_template/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/gem_template/releases/tag/v0.1.0
