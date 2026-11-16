# Recording Studio Categorisable

File a project, page, or any other type under one category. Nest categories inside each other, then filter the list to what sits in a category or anything nested under it.

This is a Recording Studio addon. It needs Recording Studio 7.1 or newer, and below 8.0.

## Install

Add the gems to the host `Gemfile`. `recording_studio` and `flat_pack` are GitHub gems.

```ruby
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v7.2.0"
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.377"
gem "recording_studio_categorisable", github: "bowerbird-app/RecordingStudio_categorisable", tag: "v0.1.0"
```

Then:

```bash
bin/rails generate recording_studio_categorisable:install
bin/rails generate recording_studio_categorisable:migrations
bin/rails db:migrate
bin/rails tailwindcss:build
```

The installer mounts the screens at `/categories`. Change the path with `--mount-path`.

## Turn it on

Pick the root types that can hold a top-level category:

```ruby
# config/initializers/recording_studio_categorisable.rb
RecordingStudioCategorisable.configure do |config|
  config.category_holder_types = ["Workspace"]
end
```

Register the two built-in types next to the host's own types:

```ruby
config.recordable_types = [
  "Workspace",
  "Project",
  "RecordingStudioCategorisable::Category",
  "RecordingStudioCategorisable::Assignment"
]
```

Enable the capability on each type that can be filed. This is the only switch:

```ruby
class Project < ApplicationRecord
  recording_studio_recordable label: "Project", root: false, allowed_parent_types: ["Workspace"]

  include RecordingStudio::Capabilities::Categorisable.to
end
```

A type that does not include it cannot take a category.

## What people can do

- Add a category under a holder, or under another category.
- Save one category on an item, change it, or clear it.
- Open a category and see the items filed there, including items in nested categories.

Drop the picker onto a host screen:

```erb
<%= recording_studio_category_picker(recording) %>
```

The category list, the add form, and the filter live in this gem. Staff tools for the whole site stay in Recording Studio Admin.

Writes go through Recording Studio (`record`, `revise`, and `log_event!`). When Accessible is installed, changing a category requires edit access on that item, and adding a category requires edit access on its parent. This gem does not add its own grant rules.

## Host migrations

Run these on a host that is new to this gem. Generate them. Do not paste them by hand.

1. `bin/rails generate recording_studio:migrations`
   Recording Studio 7.2 adds `index_rs_events_on_timeline` on `recording_studio_events (occurred_at, created_at, id)`.
2. `bin/rails generate recording_studio_accessible:migrations` when the host uses Accessible.
3. `bin/rails generate recording_studio_categorisable:migrations`
   - `recording_studio_categorisable_categories` (`name`)
   - `recording_studio_categorisable_assignments` (`category_recording_id`)
4. `bin/rails generate recording_studio:single_child_index`
   A category choice is one per item. The index matches that rule. The Ruby check still applies if you skip the index.

Then `bin/rails db:migrate`.

## One category

An item has one category. That choice is a single child recording pointing at the category. Clearing it revises the choice to a blank category. Categories themselves are recordings, so a nest is a parent and a child. There is no second tree and no join table.

## Upgrade

0.1.0 is the first release. Nothing on `main` before this version shipped categories, and no host Gemfile referenced this gem.

Hosts that were generated from the old addon template should drop the template pages migration, the copied hooks, and the copied service base class. Require `recording_studio_categorisable` and follow the install steps above. Core 7 also asks the host to set `config.authorize_write`, call `create_root_recording!` for a new root, and use `recording_studio_layout`.

## Development

The dummy app signs in as `admin@admin.com` / `Password`. It uses the shared Recording Studio master key. Do not commit `master.key`.

```bash
bundle install
bundle install --gemfile test/dummy/Gemfile
cd test/dummy && bin/rails db:prepare db:seed
cd test/dummy && bin/rails tailwindcss:build
bundle exec rake test
bundle exec rubocop
cd test/dummy && bin/rails test
```
