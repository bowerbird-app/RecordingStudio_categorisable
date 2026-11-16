# Changelog

## 0.1.0

First release of `recording_studio_categorisable`.

A host can enable categories on chosen types with `include RecordingStudio::Capabilities::Categorisable.to`. People can add a category, nest it under another category, file an item under one category, clear that choice, and filter to the items in a category.

Requires `recording_studio` `>= 7.1` and `< 8.0`. The dummy app tracks Recording Studio 7.2.0 and Flatpack 0.1.377.

Host migrations for this version:

- `bin/rails generate recording_studio:migrations`, including Recording Studio 7.2's `index_rs_events_on_timeline` on `recording_studio_events (occurred_at, created_at, id)`.
- `bin/rails generate recording_studio_accessible:migrations` when the host uses Accessible.
- `bin/rails generate recording_studio_categorisable:migrations` for `recording_studio_categorisable_categories` and `recording_studio_categorisable_assignments`.
- `bin/rails generate recording_studio:single_child_index` so the one-category-per-item rule is also enforced in the database.

An item has one category. The choice is a single child recording, and clearing it revises that child to a blank category. Nested categories are parent and child recordings. There is no join table.

This gem was never released before 0.1.0. The template pages, copied hooks, and copied service base class are gone.
