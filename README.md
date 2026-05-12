# RecordingStudio Categorisable

`recording_studio_categorisable` is a mountable Rails engine that stores category groups and category items as Recording Studio recordables.

## What it provides

- `RecordingStudioCategorisable::CategoryGroup` and `RecordingStudioCategorisable::CategoryItem` recordables
- explicit categorisable registration APIs for single-select and multi-select fields
- usage counting based on registered category fields, not database guessing
- deletion guards for groups and items that are still in use
- mounted management UI at `/recording_studio_categorisable`
- a dummy app that demonstrates category management and a page edit flow

## Data model

- category groups and category items are recordables
- groups can live anywhere in the current recording tree
- items are created beneath a group recording
- categorised recordables store category **item recording IDs**
- historical revisions stay immutable because assignments live on the revised recordable snapshot

## Registering categorisable recordables

Include the concern on a recordable model and declare each field explicitly:

```ruby
class Page < ApplicationRecord
  include RecordingStudioCategorisable::Categorisable

  categorises :status_category_item_recording_id,
              selection: :single,
              category_group_slug: "page-status",
              label: "Status"

  categorises :topic_category_item_recording_ids,
              selection: :multiple,
              category_group_slug: "page-topics",
              label: "Topics"
end
```

The registration powers:

- option lookup for the mounted UI and host forms
- assignment sanitisation
- usage reporting for destructive actions

## Mounted UI

Mount the engine and expose a current root recording resolver:

```ruby
# config/routes.rb
mount RecordingStudioCategorisable::Engine, at: "/recording_studio_categorisable"
```

```ruby
# config/initializers/recording_studio_categorisable.rb
RecordingStudioCategorisable.configure do |config|
  config.ui_title = "Categories"
  config.root_recording_resolver = ->(controller) { controller.send(:current_root_recording) }
end
```

The mounted UI supports:

- listing category groups
- creating groups anywhere in the current root tree
- creating and editing category items inside a group
- usage-aware deletion guards for groups and items

## Dummy app

The dummy app shows the intended workflow:

- seeded admin login: `admin@admin.com` / `Password`
- mounted Recording Studio engine
- mounted categorisable engine
- page editor with one single-select field and one multi-select field

Useful dummy routes:

- `/`
- `/recording_studio_categorisable`
- `/pages`

## Validation

Root validation:

```bash
bundle _4.0.0_ exec rubocop
bundle _4.0.0_ exec rake app:test
```

Dummy app validation:

```bash
cd test/dummy
bundle _4.0.0_ exec rails db:drop db:create db:migrate db:seed
bundle _4.0.0_ exec rails test
bundle _4.0.0_ exec rails zeitwerk:check
bundle _4.0.0_ exec rails tailwindcss:build
```
