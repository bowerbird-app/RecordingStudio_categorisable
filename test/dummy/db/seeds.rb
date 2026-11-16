# frozen_string_literal: true

category_named = lambda do |root, parent, name|
  RecordingStudio::Recording.kept.where(
    root_recording: root,
    parent_recording: parent,
    recordable_type: "RecordingStudioCategorisable::Category"
  ).includes(:recordable).find { |recording| recording.recordable.name == name }
end

user = User.find_or_create_by!(email: "admin@admin.com") do |record|
  record.password = "Password"
  record.password_confirmation = "Password"
end

workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
previous_actor = Current.actor
Current.actor = user

begin
  root = RecordingStudio.create_root_recording!(workspace, actor: user)
  result = RecordingStudioAccessible.bootstrap_owner_access!(recording: root, actor: user)
  raise result.error if result.failure?

  project = Project.find_or_create_by!(name: "Launch notes")
  project_recording = RecordingStudio::Recording.kept.find_by(recordable: project) ||
                      root.record(project, actor: user, parent_recording: root)

  unfiled = Project.find_or_create_by!(name: "Unfiled notes")
  RecordingStudio::Recording.kept.find_by(recordable: unfiled) ||
    root.record(unfiled, actor: user, parent_recording: root)

  news = category_named.call(root, root, "News") ||
         RecordingStudioCategorisable.record_category(parent_recording: root, name: "News", actor: user)
  product = category_named.call(root, news, "Product") ||
            RecordingStudioCategorisable.record_category(parent_recording: news, name: "Product", actor: user)

  project_recording.assign_category!(product, actor: user) if project_recording.category_recording.nil?
ensure
  Current.actor = previous_actor
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: workspace '#{workspace.name}'"
