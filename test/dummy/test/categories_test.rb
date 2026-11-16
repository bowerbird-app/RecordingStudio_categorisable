# frozen_string_literal: true

require "test_helper"

class CategoriesTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "owner-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    Current.actor = @user
    workspace = Workspace.create!(name: "Workspace #{SecureRandom.hex(4)}")
    @root = RecordingStudio.create_root_recording!(workspace, actor: @user)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?

    project = Project.create!(name: "Launch notes")
    @project_recording = @root.record(project, actor: @user, parent_recording: @root)
  end

  test "enabling the capability lets a project take a category" do
    news = RecordingStudioCategorisable.record_category(parent_recording: @root, name: "News", actor: @user)

    @project_recording.assign_category!(news, actor: @user)

    assert_equal news, @project_recording.reload.category_recording
    assert @project_recording.events.exists?(action: "category_assigned")
  end

  test "a type that has not enabled categories cannot take one" do
    news = RecordingStudioCategorisable.record_category(parent_recording: @root, name: "News", actor: @user)

    error = assert_raises(RecordingStudio::CapabilityDisabled) do
      @root.assign_category!(news, actor: @user)
    end
    assert_match "Workspace", error.message
  end

  test "removing a category clears it" do
    news = RecordingStudioCategorisable.record_category(parent_recording: @root, name: "News", actor: @user)
    @project_recording.assign_category!(news, actor: @user)

    @project_recording.remove_category!(actor: @user)

    assert_nil @project_recording.reload.category_recording
    assert @project_recording.events.exists?(action: "category_removed")
  end

  test "a nested category is included when filtering by its parent" do
    news = RecordingStudioCategorisable.record_category(parent_recording: @root, name: "News", actor: @user)
    product = RecordingStudioCategorisable.record_category(parent_recording: news, name: "Product", actor: @user)
    @project_recording.assign_category!(product, actor: @user)

    assert_equal news, product.parent_recording
    assert_includes RecordingStudioCategorisable.recordings_in_category(news), @project_recording
    assert_includes RecordingStudioCategorisable.recordings_in_category(product), @project_recording

    @project_recording.remove_category!(actor: @user)

    assert_empty RecordingStudioCategorisable.recordings_in_category(news)
  end

  test "changing the category keeps the previous choice snapshot" do
    news = RecordingStudioCategorisable.record_category(parent_recording: @root, name: "News", actor: @user)
    product = RecordingStudioCategorisable.record_category(parent_recording: news, name: "Product", actor: @user)
    @project_recording.assign_category!(news, actor: @user)
    choice = @project_recording.child_recordings.of_type(RecordingStudioCategorisable::Assignment.name).first
    previous_id = choice.recordable_id

    @project_recording.assign_category!(product, actor: @user)

    assert_equal product, @project_recording.reload.category_recording
    assert_equal news.id, RecordingStudioCategorisable::Assignment.find(previous_id).category_recording_id
    assert_not_equal previous_id, choice.reload.recordable_id
  end

  test "someone without access cannot change the category" do
    news = RecordingStudioCategorisable.record_category(parent_recording: @root, name: "News", actor: @user)
    stranger = User.create!(
      email: "stranger-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )

    assert_raises(RecordingStudioCategorisable::NotAllowed) do
      @project_recording.assign_category!(news, actor: stranger)
    end
    assert_nil @project_recording.reload.category_recording
  end
end
