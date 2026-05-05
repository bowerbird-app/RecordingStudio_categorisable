# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require "devise/test/integration_helpers"

class ActiveSupport::TestCase
  parallelize(workers: 1)

  setup do
    Current.reset
  end

  teardown do
    Current.reset
  end

  private

  def create_user(email:)
    User.create!(email: email, password: "Password", password_confirmation: "Password")
  end

  def create_workspace(name:)
    Workspace.create!(name: name)
  end

  def create_root_recording(recordable:)
    RecordingStudio::Recording.create!(recordable: recordable, parent_recording_id: nil)
  end

  def grant_root_access!(actor:, root_recording:, role: :admin)
    access = RecordingStudio::Access.create!(actor: actor, role: role)

    RecordingStudio::Recording.create!(
      recordable: access,
      parent_recording: root_recording,
      root_recording: root_recording
    )
  end

  def create_category_group!(root_recording:, label:)
    root_recording.record(
      RecordingStudioCategorisable::CategoryGroup.new(label: label),
      actor: Current.actor,
      parent_recording: root_recording
    )
  end

  def create_category_item!(group_recording:, label:)
    group_recording.record(
      RecordingStudioCategorisable::CategoryItem.new(label: label),
      actor: Current.actor,
      parent_recording: group_recording
    )
  end

  def create_project_recording!(root_recording:, name:)
    project = Project.create!(name: name, status: "active")

    RecordingStudio::Recording.create!(
      recordable: project,
      parent_recording: root_recording,
      root_recording: root_recording
    )
  end

  def create_category_assignment!(target_recording:, category_item_recording:)
    target_recording.record(
      RecordingStudioCategorisable::CategoryAssignment.new(category_item_recording_id: category_item_recording.id),
      actor: Current.actor,
      parent_recording: target_recording
    )
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
