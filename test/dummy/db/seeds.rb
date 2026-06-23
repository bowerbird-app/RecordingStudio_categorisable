# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

def ensure_root_access(root_recording:, actor:, role:, manager_actor:)
  return unless defined?(RecordingStudioAccessible)

  existing_access = root_recording
    .child_recordings
    .where(recordable_type: "RecordingStudio::Access")
    .includes(:recordable)
    .find do |recording|
      access = recording.recordable
      access.actor == actor && access.role.to_s == role.to_s
    end

  return existing_access.recordable if existing_access

  if role.to_sym == :admin && actor == manager_actor
    RecordingStudioAccessible::AccessCreationContext.allow do
      access_recording = root_recording.record(RecordingStudio::Access, parent_recording: root_recording) do |access|
        access.actor = actor
        access.role = role
      end

      return access_recording.recordable
    end
  end

  result = RecordingStudioAccessible.grant_access(
    recording: root_recording,
    actor: actor,
    role: role,
    manager_actor: manager_actor
  )

  return result.value if result.success?

  raise "Failed to grant #{role} access to #{actor.email}: #{result.error}"
end

# Create the admin user
admin_user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

# Create a viewer user
viewer_user = User.find_or_create_by!(email: "viewer@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

# Create the workspace recordable
workspace = Workspace.find_or_create_by!(name: "Studio Workspace")

# Create the root recording
root_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  recordable: workspace,
  parent_recording_id: nil
)

Current.actor = admin_user
ensure_root_access(root_recording: root_recording, actor: admin_user, role: :admin, manager_actor: admin_user)
ensure_root_access(root_recording: root_recording, actor: viewer_user, role: :view, manager_actor: admin_user)

# Category groups and items are created by the engine initializer from
# RecordingStudioCategorisable.category_definitions.
# Find the already-seeded groups by key to use when creating sample pages/briefs.
status_group_recording = root_recording.recordings_query(
  include_children: true,
  type: RecordingStudioCategorisable::CategoryGroup
).includes(:recordable).find { |recording| recording.recordable.key == "page-status" }

topics_group_recording = root_recording.recordings_query(
  include_children: true,
  type: RecordingStudioCategorisable::CategoryGroup
).includes(:recordable).find { |recording| recording.recordable.key == "page-topics" }

# Find category items by key
def find_item_by_key(group_recording, key)
  group_recording&.child_recordings
    &.of_type(RecordingStudioCategorisable::CategoryItem)
    &.includes(:recordable)
    &.find { |recording| recording.recordable.key == key }
end

page_recording = root_recording.recordings_query(type: Page).includes(:recordable).first

unless page_recording
  published_item_recording = find_item_by_key(status_group_recording, "published")
  product_item_recording = find_item_by_key(topics_group_recording, "product")
  studio_item_recording = find_item_by_key(topics_group_recording, "studio")

  root_recording.record(Page) do |page|
    page.title = "Studio launch plan"
    page.body = "Seeded page used to exercise the categorisable edit flow in the dummy app."
    page.status_category_item_recording_id = published_item_recording&.id
    page.topic_category_item_recording_ids = [product_item_recording&.id, studio_item_recording&.id].compact
  end
end

brief_recording = root_recording.recordings_query(type: Brief).includes(:recordable).first

unless brief_recording
  draft_item_recording = find_item_by_key(status_group_recording, "draft")

  root_recording.record(Brief) do |brief|
    brief.title = "Studio status snapshot"
    brief.body = "Seeded brief used to demonstrate a single-select categorisable field."
    brief.status_category_item_recording_id = draft_item_recording&.id
  end
end

if status_group_recording && topics_group_recording
  puts "Seeded: Category groups '#{status_group_recording.recordable.name}' and '#{topics_group_recording.recordable.name}'"
end
