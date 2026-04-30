# RecordingStudioCategorisable

A Rails engine addon for [RecordingStudio](https://github.com/bowerbird-app/RecordingStudio) that provides flexible category management. Create category groups, define category items, and assign categories to any recording in your RecordingStudio installation.

## Features

- **Category Groups**: Organize categories into logical groups (e.g., "Project Status", "Priority", "Team")
- **Category Items**: Define individual category values within each group
- **Category Assignments**: Assign categories to recordings for organization and filtering
- **RecordingStudio Integration**: All categories are persisted as RecordingStudio recordings, providing full event history and tree structure
- **Authorization**: Integrates with `RecordingStudioAccessible` when present for access control
- **FlatPack UI**: Clean, accessible interface using FlatPack ViewComponents
- **Flexible API**: Query helpers for finding categories, assignments, and related recordings

## Architecture

### Recording Structure

All category entities are stored as RecordingStudio recordings with minimal recordable payloads:

```
Workspace (root recording)
├── CategoryGroup (label: "Project Status")
│   ├── CategoryItem (label: "Active")
│   ├── CategoryItem (label: "On Hold")
│   └── CategoryItem (label: "Completed")
├── CategoryGroup (label: "Priority")
│   ├── CategoryItem (label: "Low")
│   ├── CategoryItem (label: "Medium")
│   └── CategoryItem (label: "High")
└── Any Recording
    └── CategoryAssignment (category_item_recording_id: <UUID>)
```

### Recordable Types

- **`RecordingStudioCategorisable::CategoryGroup`**: Container for related category items
  - Payload: `{ label: "Group Name" }`
- **`RecordingStudioCategorisable::CategoryItem`**: Individual category option within a group
  - Payload: `{ label: "Item Name" }`
- **`RecordingStudioCategorisable::CategoryAssignment`**: Links a recording to a category item
  - Payload: `{ category_item_recording_id: <UUID> }` (reference to category item recording)

## Installation

### 1. Add to Gemfile

```ruby
gem "recording_studio_categorisable", github: "bowerbird-app/RecordingStudio_categorisable"
```

### 2. Bundle install

```bash
bundle install
```

### 3. Register recordable types

In your `config/initializers/recording_studio.rb`:

```ruby
RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "RecordingStudioCategorisable::CategoryGroup",
    "RecordingStudioCategorisable::CategoryItem",
    "RecordingStudioCategorisable::CategoryAssignment"
    # ... your other recordable types
  ]
end
```

### 4. Mount the engine

In your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount RecordingStudioCategorisable::Engine, at: "/categories"
  # ... other routes
end
```

### 5. Add navigation (optional)

Update your app's navigation to include a link to the category management interface:

```erb
<%= link_to "Categories", recording_studio_categorisable.root_path %>
```

## Usage

### Creating Category Groups and Items

Via the UI:
1. Navigate to `/categories`
2. Click "New Category Group"
3. Create a group (e.g., "Project Status")
4. Add category items (e.g., "Active", "On Hold", "Completed")

Via code:

```ruby
# Create a category group
result = root_recording.record(RecordingStudioCategorisable::CategoryGroup) do |group|
  group.label = "Project Status"
end

status_group_recording = result.recording if result.success?

# Add category items to the group
result = status_group_recording.record(RecordingStudioCategorisable::CategoryItem) do |item|
  item.label = "Active"
end

active_item_recording = result.recording if result.success?
```

### Assigning Categories to Recordings

```ruby
# Assign a category to any recording
result = target_recording.record(RecordingStudioCategorisable::CategoryAssignment) do |assignment|
  assignment.category_item_recording = active_item_recording
end
```

### Query Helpers

```ruby
# Find all category items in a group
category_group = CategoryGroup.find(group_id)
items = category_group.category_items

# Find the parent group of a category item
category_item = CategoryItem.find(item_id)
group = category_item.category_group

# Find all assignments of a category item
assignments = category_item.category_assignments

# Find the target recording of an assignment
assignment = CategoryAssignment.find(assignment_id)
target = assignment.target_recording
category_item = assignment.category_item
```

## Authorization

When `RecordingStudioAccessible` is present, the addon automatically enforces authorization:

```ruby
# In controllers, authorization is checked before actions
def update
  authorize_action!(@category_group_recording)
  # ... action logic
end
```

The authorization integrates with RecordingStudioAccessible's policy system, checking permissions based on the current actor and the recording's access controls.

## Development

### Quick Start with GitHub Codespaces

1. Click **Code** → **Codespaces** → **Create codespace**
2. Wait for setup to complete
3. Run:
   ```bash
   cd test/dummy
   bin/rails db:setup
   bin/dev
   ```
4. Open port 3000 and visit `/categories`

### Login Credentials

| Field    | Value             |
|----------|-------------------|
| Email    | admin@admin.com   |
| Password | Password          |

### Dummy App

The `test/dummy` app demonstrates:
- Complete category management workflow
- Integration with RecordingStudio root recording pattern
- FlatPack component usage
- Authorization flow (when RecordingStudioAccessible is present)
- Seed data with 4 category groups and multiple items

### Running Tests

Due to the Ruby version requirement (3.3.0+), tests should be run in an environment with Ruby 3.3 or higher:

```bash
bundle exec rake test
```

## Tech Stack

| Component       | Version |
|-----------------|---------|
| Ruby            | 3.3+    |
| Rails           | 8.1+    |
| PostgreSQL      | 16      |
| RecordingStudio | v0.1.0-alpha |
| FlatPack        | v0.1.33 |

## Design Principles

1. **Minimal Recordable Payloads**: Category recordables contain only essential data (label for groups/items, category item recording reference for assignments)
2. **Leverage RecordingStudio**: All categorization data flows through recordings, providing full event history, trash/restore, and tree structure
3. **Authorization-Ready**: Seamless integration with RecordingStudioAccessible without hard dependencies
4. **FlatPack-First**: All UI built with standardized FlatPack components for consistency and maintainability
5. **No Taxonomy Overbuild**: Simple, flat category structure without unnecessary hierarchy or complexity

## License

This project is licensed under the MIT License.
