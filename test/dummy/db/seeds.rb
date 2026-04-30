# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
root_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  recordable: workspace,
  parent_recording_id: nil
)

Current.actor = user
access = RecordingStudio::Access.find_or_create_by!(actor: user, role: :admin)
RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: root_recording.id,
  recordable: access
)

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"

puts "\nSeeding category data..."

def ensure_category_group(root_recording, label)
  existing = root_recording.child_recordings.includes(:recordable).find do |recording|
    recording.recordable_type == RecordingStudioCategorisable::CategoryGroup.name &&
      recording.recordable&.label == label
  end
  return existing if existing

  root_recording.record(
    RecordingStudioCategorisable::CategoryGroup.new(label: label),
    actor: Current.actor,
    parent_recording: root_recording
  )
end

def ensure_category_item(group_recording, label)
  existing = group_recording.child_recordings.includes(:recordable).find do |recording|
    recording.recordable_type == RecordingStudioCategorisable::CategoryItem.name &&
      recording.recordable&.label == label
  end
  return existing if existing

  group_recording.record(
    RecordingStudioCategorisable::CategoryItem.new(label: label),
    actor: Current.actor,
    parent_recording: group_recording
  )
end

groups = {
  "Project Status" => ["Planning", "Active", "On Hold", "Completed", "Cancelled"],
  "Priority" => ["Low", "Medium", "High", "Critical"],
  "Team" => ["Engineering", "Design", "Product", "Marketing", "Sales"]
}
item_recordings = {}

groups.each do |group_label, item_labels|
  group_recording = ensure_category_group(root_recording, group_label)
  puts "Created category group: #{group_label}"

  item_labels.each do |item_label|
    item_recording = ensure_category_item(group_recording, item_label)
    item_recordings[[group_label, item_label]] = item_recording
    puts "  - Created category item: #{item_label}"
  end
end

project = Project.find_or_create_by!(name: "Launch mobile studio") do |record|
  record.description = "Demo project used to showcase category assignments"
end
project_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  recordable: project,
  parent_recording_id: root_recording.id,
  root_recording_id: root_recording.id
)

[
  item_recordings[["Project Status", "Active"]],
  item_recordings[["Priority", "High"]],
  item_recordings[["Team", "Engineering"]]
].compact.each do |category_item_recording|
  next if project_recording.child_recordings.includes(:recordable).any? do |recording|
    recording.recordable_type == RecordingStudioCategorisable::CategoryAssignment.name &&
      recording.recordable&.category_item_recording_id == category_item_recording.id
  end

  project_recording.record(
    RecordingStudioCategorisable::CategoryAssignment.new(category_item_recording_id: category_item_recording.id),
    actor: Current.actor,
    parent_recording: project_recording
  )
end

puts "\nCategory seeding complete!"
puts "Seeded project '#{project.name}' with category assignments."
puts "Visit /categories to explore the category management interface."
