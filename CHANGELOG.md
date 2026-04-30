# Changelog

All notable changes to RecordingStudioCategorisable will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-04-30

### Added
- Initial release of RecordingStudioCategorisable
- Category Group model and CRUD operations
- Category Item model and CRUD operations  
- Category Assignment model for linking recordings to categories
- Full RecordingStudio integration with recordings/recordables/events
- FlatPack-based UI components for all views
- Blank layout consistent with RecordingStudio addon patterns
- Authorization integration with RecordingStudioAccessible (when present)
- Query helpers for category lookups and associations
- Comprehensive dummy app with seed data
- Demo category groups: Project Status, Priority, Team, Tags
- Full documentation and usage examples in README

### Technical Details
- All category data stored as RecordingStudio recordings
- Minimal recordable payloads (label for groups/items, recording reference for assignments)
- Namespace isolation under RecordingStudioCategorisable module
- Routes mounted at /categories
- Rails 8.1+ and Ruby 3.3+ compatibility

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_categorisable/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_categorisable/releases/tag/v0.1.0
