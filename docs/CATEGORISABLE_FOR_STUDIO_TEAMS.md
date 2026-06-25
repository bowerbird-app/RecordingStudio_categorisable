# RecordingStudio Categorisable: Plain-English Guide

This guide explains the categorisable gem for:

- people who understand recording-studio workflows
- junior developers who are new to Rails engines

The goal is to help you reason about categories using studio concepts first, then map those ideas to code.

## 1) What this gem does (in studio terms)

Think of your content as sessions in a studio archive.

- A Category Group is like a labeled rack or crate (for example: "Status", "Genre", "Mood").
- A Category Item is one label inside that crate (for example: "Draft", "Published", "Rock", "Ambient").
- A recordable (like a Page) stores the IDs of selected category items.

So instead of typing free-form tags everywhere, your app picks from controlled lists.

## 2) Core mental model

The gem is built around Recording Studio recordings.

- Category groups and category items are stored as recordables.
- A group can live anywhere under the current root recording.
- Items are child recordings under their group.
- Your model stores selected item recording IDs.

Simple picture:

```text
Root Recording
|- Category Group: page-status
|  |- Category Item: Draft
|  |- Category Item: Published
|
|- Category Group: page-topics
   |- Category Item: Production
   |- Category Item: Mixing
   |- Category Item: Mastering
```

## 3) Install and mount

Mount the engine in your app routes:

```ruby
# config/routes.rb
mount RecordingStudioCategorisable::Engine, at: "/recording_studio_categorisable"
```

Configure the engine (initializer):

```ruby
# config/initializers/recording_studio_categorisable.rb
RecordingStudioCategorisable.configure do |config|
  config.ui_title = "Categories"

  # Tell the engine how to find the current recording root.
  config.root_recording_resolver = ->(controller) { controller.send(:current_root_recording) }

  # Tell the engine who is allowed to manage categories.
  config.authorization_resolver = ->(controller) { controller.current_user.present? }
end
```

## 4) Make a model categorisable

Example model from the dummy app:

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

What this gives you:

- single-select and multi-select category fields
- lookup for available options in the current root recording
- validation/sanitization for selected IDs
- usage reporting for delete guards

## 5) Alternative: register fields in initializer

If you prefer central config instead of model macros:

```ruby
RecordingStudioCategorisable.configure do |config|
  config.register_categorisable("Page") do |registration|
    registration.single_select :status_category_item_recording_id,
                               category_group_slug: "page-status"

    registration.multi_select :topic_category_item_recording_ids,
                              category_group_slug: "page-topics"
  end
end
```

Both approaches create category field registrations.

## 6) Load options for forms

In your controller, get the registration and build field state:

```ruby
def registration
  RecordingStudioCategorisable.configuration.registration_for(Page)
end

def load_category_fields
  @category_fields = registration.fields.map do |field|
    {
      field: field,
      item_recordings: field.available_item_recordings(
        root_recording: current_root_recording,
        recordable: @page
      )
    }
  end
end
```

This returns each field plus the allowed category items.

## 7) Sanitize user input before saving

Always sanitize selected values from params:

```ruby
def sanitized_category_assignments
  registration.fields.each_with_object({}) do |field, assignments|
    assignments[field.key] = field.sanitize(
      params.dig(:page, field.attribute_name),
      root_recording: current_root_recording,
      recordable: @page
    )
  end
end
```

Then write sanitized values:

```ruby
def apply_category_assignments(page, assignments)
  registration.fields.each do |field|
    field.write(page, assignments.fetch(field.key))
  end
end
```

Why this matters:

- prevents invalid IDs from being saved
- enforces single-select vs multi-select rules
- keeps category assignments consistent with the active root tree

## 8) Form examples (single and multiple)

Single-select example:

```erb
<%= render FlatPack::Select::Component.new(
  name: "page[#{field.attribute_name}]",
  label: field.label,
  options: item_recordings.map { |item_recording| [item_recording.recordable.name, item_recording.id] },
  value: field.read(page)
) %>
```

Multi-select example:

```erb
<% selected_ids = Array(field.read(page)) %>
<% item_recordings.each do |item_recording| %>
  <%= render FlatPack::Checkbox::Component.new(
    name: "page[#{field.attribute_name}][]",
    label: item_recording.recordable.name,
    value: item_recording.id,
    checked: selected_ids.include?(item_recording.id)
  ) %>
<% end %>
```

## 9) Create and update flow example

```ruby
def create
  category_assignments = sanitized_category_assignments

  current_root_recording.record(Page) do |page|
    page.assign_attributes(page_params)
    apply_category_assignments(page, category_assignments)
  end

  redirect_to pages_path, notice: "Page created."
rescue RecordingStudioCategorisable::InvalidCategorySelectionError => error
  @page = Page.new(page_params)
  @page.errors.add(:base, "One or more category selections were invalid: #{error.message}")
  load_category_fields
  render :new, status: :unprocessable_entity
end
```

The key idea: resolve and sanitize category values before committing the recording.

## 10) Safety features in plain language

### Usage-aware delete guards

The gem can count where category items are used. If an item or group is still in use, delete can be blocked.

Studio analogy: do not throw away a label card that active sessions still depend on.

### Slug uniqueness in a root

Groups with the same slug under one root are rejected to avoid ambiguous lookups.

## 11) Common mistakes and quick fixes

1. Mistake: You forgot to include the categorisable concern.
   Fix: Add include RecordingStudioCategorisable::Categorisable in the model.

2. Mistake: Group slug in code does not match real category group slug.
   Fix: Ensure category_group_slug exactly matches the group slug used in the recordings.

3. Mistake: You write params directly to model fields.
   Fix: Use field.sanitize before field.write.

4. Mistake: Multi-select field is not an array param in the form.
   Fix: Use name like page[topic_category_item_recording_ids][].

## 12) Mini glossary

- Root recording: top-level recording context used for queries and revisions.
- Category group: a container (for example page-status).
- Category item: a selectable option inside a group.
- Registration: field configuration for a recordable type.
- Sanitization: converting and validating raw user input before save.

## 13) Practical checklist for junior devs

1. Mount the engine route.
2. Configure root and authorization resolvers.
3. Add categorises declarations to your model.
4. Load category fields in controller for the form.
5. Sanitize params and then write category values.
6. Handle InvalidCategorySelectionError and re-render form with errors.
7. Verify delete behavior for groups and items in the UI.

If you can explain those 7 steps, you already understand the gem well enough to build with it.