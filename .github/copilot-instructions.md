# Project Guidelines

## Architecture

- This repository is the Recording Studio categorisable addon, namespaced as `RecordingStudioCategorisable`.
- Categories are Recording Studio recordings. A category choice is one child recording. Do not add a second tree or a join table.
- Enable the capability with `include RecordingStudio::Capabilities::Categorisable.to`.
- The README is the product guide. The dummy app is the host that proves it.

## UI Conventions

- Flatpack is the UI system. Prefer `render FlatPack::...` over custom markup.
- People-facing copy says category, name, and save. It does not say recording, recordable, or capability.

## Testing

- `bundle exec rake test` runs the gem suite.
- `bundle exec rake app:test` also runs the dummy suite.
- `bundle exec rubocop` is the style check.
