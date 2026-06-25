# RecordingStudio Categorisable

A mountable Rails engine for managing category groups and category items inside the RecordingStudio recording tree.

This gem provides:

- a mounted management UI for category groups and items
- root-scoped capability controls for who can edit what
- model-level category references (single and multiple selection)
- idempotent category seeding from configuration
- usage-aware delete guards for safer data changes

## What Is New

Recent updates in this gem include:

- renamed legacy `slug` fields to `key` for groups and items
- root-scoped capability resolution via `root_recordable_type`
- non-unique DB index for group `key`, with uniqueness enforced per root in app logic
- update flows that preserve validation errors (re-render instead of losing form state)
- auto-seeding support for expected groups and supplemental items

## Requirements

- Ruby >= 3.3.0
- Rails ~> 8.1.0
- recording_studio >= 3.0.0
- flat_pack >= 0.1.106

## Installation

Add the gem to your application and bundle.

Then run the installer:

```bash
bin/rails generate recording_studio_categorisable:install
```

The installer:

- mounts the engine route (default `/recording_studio_categorisable`)
- adds `config/initializers/recording_studio_categorisable.rb`
- optionally adds `config/recording_studio_categorisable.yml`
- attempts to add Tailwind `@source` directives for engine and FlatPack templates

Run migrations:

```bash
bin/rails db:migrate
```

## Mount Route

If you are not using the installer, mount manually:

```ruby
# config/routes.rb
mount RecordingStudioCategorisable::Engine, at: "/recording_studio_categorisable"
```

## Basic Configuration

```ruby
# config/initializers/recording_studio_categorisable.rb
RecordingStudioCategorisable.configure do |config|
	config.ui_title = "Categories"

	# Required: resolve the root recording context for the mounted UI.
	config.root_recording_resolver = ->(controller) { controller.send(:current_root_recording) }

	# Required unless your ApplicationController provides
	# authorize_recording_studio_categorisable!
	config.authorization_resolver = ->(controller) { controller.current_user.present? }

	# Optional custom unauthorized handling.
	# config.unauthorized_response_handler = ->(controller, exception) do
	#   controller.render plain: exception.message, status: :forbidden
	# end
end
```

## Capability Model

The API is split into three capability layers:

1. `CategoryGroup.enabled`: controls group-level behavior (rename, description updates, etc)
2. `CategoryItems.enabled`: controls item-level behavior (create, update, delete)
3. `Reference.enabled`: wires model attributes to category groups

### Root-Scoped Group and Item Capabilities

Use `root_recordable_type` to scope capabilities to a root class:

```ruby
RecordingStudioCategorisable::Capabilities::CategoryGroup.enabled(
	key: "page-status",
	name: "Page Status",
	root_recordable_type: "Workspace",
	allow: {
		rename: true,
		update_description: true,
		update_key: false
	}
)

RecordingStudioCategorisable::Capabilities::CategoryItems.enabled(
	group_key: "page-status",
	root_recordable_type: "Workspace",
	allow: {
		create: true,
		update_name: true,
		update_description: true,
		orderable: true,
		update_key: false,
		delete: true
	}
)
```

Notes:

- if `root_recordable_type` is omitted, capability acts as global fallback
- group/item capabilities are not model-field declarations; they are policy/config

### Per-Model References

References are registered per recordable class. They are not inherited from a root model.

```ruby
class Page < ApplicationRecord
	recording_studio_recordable label: "Page", root: false, allowed_parent_types: ["Workspace", "Page"]

	RecordingStudioCategorisable::Capabilities::Reference.enabled(
		recordable: self,
		attribute_name: :status_category_item_recording_id,
		selection: :single,
		category_group_key: "page-status",
		label: "Status"
	)

	RecordingStudioCategorisable::Capabilities::Reference.enabled(
		recordable: self,
		attribute_name: :topic_category_item_recording_ids,
		selection: :multiple,
		category_group_key: "page-topics",
		label: "Topics"
	)
end
```

If another child model (for example `Brief`) also needs category references, register references for that model too.

## Defining Category Seeds

You can define default groups/items through `category_definitions`:

```ruby
RecordingStudioCategorisable.configure do |config|
	config.category_definitions = [
		{
			group_key: "page-status",
			group_name: "Page Status",
			group_description: "Single-select lifecycle state.",
			items: [
				{ key: "draft", name: "Draft" },
				{ key: "published", name: "Published" }
			]
		},
		{
			group_key: "page-topics",
			group_name: "Page Topics",
			group_description: "Multi-select taxonomy for page content.",
			items: [
				{ key: "product", name: "Product" },
				{ key: "studio", name: "Studio" }
			]
		}
	]
end
```

Seeding is idempotent and skips keys that already exist (including tombstones).

## Safety Behaviors

The mounted UI includes guardrails:

- deletion blocking when a category item/group is still in use
- protection against cyclic group moves
- scoped capability checks based on the current root recording type
- validation-first updates that re-render forms with errors

## Using Hooks

The gem exposes lifecycle and extension hooks:

- `before_initialize`
- `on_configuration`
- `after_initialize`
- `before_service`, `after_service`, `around_service`
- `extend_model`
- `extend_controller`

Example:

```ruby
RecordingStudioCategorisable.configure do |config|
	config.hooks.after_initialize do
		Rails.logger.info("RecordingStudioCategorisable initialized")
	end
end
```

## Running Tests In This Repository

From the repository root:

```bash
bundle exec rake test
```

## License

Released under the MIT License.
