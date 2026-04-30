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

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"

# Seed category groups and items
puts "\nSeeding category data..."

# Project Status category group
status_result = root_recording.record(RecordingStudioCategorisable::CategoryGroup) do |group|
  group.label = "Project Status"
end

if status_result.success?
  status_recording = status_result.recording
  puts "Created category group: Project Status"
  
  # Add status items
  ["Planning", "Active", "On Hold", "Completed", "Cancelled"].each do |label|
    item_result = status_recording.record(RecordingStudioCategorisable::CategoryItem) do |item|
      item.label = label
    end
    puts "  - Created category item: #{label}" if item_result.success?
  end
end

# Priority category group
priority_result = root_recording.record(RecordingStudioCategorisable::CategoryGroup) do |group|
  group.label = "Priority"
end

if priority_result.success?
  priority_recording = priority_result.recording
  puts "Created category group: Priority"
  
  # Add priority items
  ["Low", "Medium", "High", "Critical"].each do |label|
    item_result = priority_recording.record(RecordingStudioCategorisable::CategoryItem) do |item|
      item.label = label
    end
    puts "  - Created category item: #{label}" if item_result.success?
  end
end

# Team category group
team_result = root_recording.record(RecordingStudioCategorisable::CategoryGroup) do |group|
  group.label = "Team"
end

if team_result.success?
  team_recording = team_result.recording
  puts "Created category group: Team"
  
  # Add team items
  ["Engineering", "Design", "Product", "Marketing", "Sales"].each do |label|
    item_result = team_recording.record(RecordingStudioCategorisable::CategoryItem) do |item|
      item.label = label
    end
    puts "  - Created category item: #{label}" if item_result.success?
  end
end

# Tags category group
tags_result = root_recording.record(RecordingStudioCategorisable::CategoryGroup) do |group|
  group.label = "Tags"
end

if tags_result.success?
  tags_recording = tags_result.recording
  puts "Created category group: Tags"
  
  # Add tag items
  ["Bug", "Feature", "Enhancement", "Documentation", "Research"].each do |label|
    item_result = tags_recording.record(RecordingStudioCategorisable::CategoryItem) do |item|
      item.label = label
    end
    puts "  - Created category item: #{label}" if item_result.success?
  end
end

puts "\nCategory seeding complete!"
puts "Visit /categories to explore the category management interface."
