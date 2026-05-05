# frozen_string_literal: true

require "test_helper"

class CategorySecurityTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user(email: "owner@example.com")

    @workspace = create_workspace(name: "Primary Workspace")
    @root_recording = create_root_recording(recordable: @workspace)

    Current.actor = @user
    grant_root_access!(actor: @user, root_recording: @root_recording)

    @group_recording = create_category_group!(root_recording: @root_recording, label: "Priority")
    @item_recording = create_category_item!(group_recording: @group_recording, label: "High")
    @other_group_recording = create_category_group!(root_recording: @root_recording, label: "Status")
    @other_group_item_recording = create_category_item!(group_recording: @other_group_recording, label: "Active")

    @project_recording = create_project_recording!(root_recording: @root_recording, name: "Console refresh")
    @other_project_recording = create_project_recording!(root_recording: @root_recording, name: "Mic inventory")
    @assignment_recording = create_category_assignment!(
      target_recording: @other_project_recording,
      category_item_recording: @item_recording
    )

    @other_workspace = create_workspace(name: "Secondary Workspace")
    @other_root_recording = create_root_recording(recordable: @other_workspace)
    grant_root_access!(actor: @user, root_recording: @other_root_recording)
    @other_root_group_recording = create_category_group!(root_recording: @other_root_recording, label: "External")
    @other_root_item_recording = create_category_item!(group_recording: @other_root_group_recording, label: "Leaked")

    Current.reset
    sign_in @user
  end

  test "category assignment choices stay scoped to the target root recording" do
    get "/categories/recordings/#{@project_recording.id}/category_assignments/new"

    assert_response :success
    assert_includes response.body, "High"
    assert_includes response.body, "Active"
    refute_includes response.body, "Leaked"
  end

  test "nested category item routes reject items outside the selected group" do
    get "/categories/category_groups/#{@other_group_recording.id}/category_items/#{@item_recording.id}"

    assert_redirected_to "/"
    follow_redirect!
    assert_includes response.body, "Recording not found."
  end

  test "nested category assignment destroy rejects assignments outside the selected target recording" do
    delete "/categories/recordings/#{@project_recording.id}/category_assignments/#{@assignment_recording.id}"

    assert_redirected_to "/"
    follow_redirect!
    assert_includes response.body, "Recording not found."
  end
end
