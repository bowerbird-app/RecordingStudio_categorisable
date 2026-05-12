# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create the admin user
user = User.find_or_create_by!(email: "admin@admin.com") do |u|
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

# Grant root-level admin access to the admin user
Current.actor = user
access = RecordingStudio::Access.find_or_create_by!(actor: user, role: :admin)
RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: root_recording.id,
  recordable: access
)

status_group_recording = root_recording.recordings_query(
  include_children: true,
  type: RecordingStudioCategorisable::CategoryGroup
).includes(:recordable).find { |recording| recording.recordable.slug == "page-status" }

unless status_group_recording
  status_group_recording = root_recording.record(RecordingStudioCategorisable::CategoryGroup) do |group|
    group.name = "Page status"
    group.slug = "page-status"
    group.description = "Single-select lifecycle state for pages."
  end
end

topics_group_recording = root_recording.recordings_query(
  include_children: true,
  type: RecordingStudioCategorisable::CategoryGroup
).includes(:recordable).find { |recording| recording.recordable.slug == "page-topics" }

unless topics_group_recording
  topics_group_recording = root_recording.record(RecordingStudioCategorisable::CategoryGroup) do |group|
    group.name = "Page topics"
    group.slug = "page-topics"
    group.description = "Multi-select taxonomy for page content."
  end
end

{
  status_group_recording => [
    { name: "Draft", slug: "draft", position: 1 },
    { name: "Published", slug: "published", position: 2 }
  ],
  topics_group_recording => [
    { name: "Product", slug: "product", position: 1 },
    { name: "Studio", slug: "studio", position: 2 },
    { name: "Launch", slug: "launch", position: 3 }
  ]
}.each do |group_recording, items|
  existing_slugs = group_recording.child_recordings.of_type(RecordingStudioCategorisable::CategoryItem)
                        .includes(:recordable)
                        .map { |recording| recording.recordable.slug }

  items.each do |attributes|
    next if existing_slugs.include?(attributes.fetch(:slug))

    root_recording.record(RecordingStudioCategorisable::CategoryItem, parent_recording: group_recording) do |item|
      item.name = attributes.fetch(:name)
      item.slug = attributes.fetch(:slug)
      item.position = attributes.fetch(:position)
      item.description = "#{attributes.fetch(:name)} category item"
    end
  end
end

page_recording = root_recording.recordings_query(type: Page).includes(:recordable).first

unless page_recording
  published_item_recording = status_group_recording.child_recordings.of_type(RecordingStudioCategorisable::CategoryItem)
                            .includes(:recordable)
                            .find { |recording| recording.recordable.slug == "published" }
  product_item_recording = topics_group_recording.child_recordings.of_type(RecordingStudioCategorisable::CategoryItem)
                          .includes(:recordable)
                          .find { |recording| recording.recordable.slug == "product" }
  studio_item_recording = topics_group_recording.child_recordings.of_type(RecordingStudioCategorisable::CategoryItem)
                         .includes(:recordable)
                         .find { |recording| recording.recordable.slug == "studio" }

  root_recording.record(Page) do |page|
    page.title = "Studio launch plan"
    page.body = "Seeded page used to exercise the categorisable edit flow in the dummy app."
    page.status_category_item_recording_id = published_item_recording&.id
    page.topic_category_item_recording_ids = [product_item_recording&.id, studio_item_recording&.id].compact
  end
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Category groups '#{status_group_recording.recordable.name}' and '#{topics_group_recording.recordable.name}'"
