require "test_helper"

class RootSwitchingTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.find_by!(email: "admin@admin.com")
  end

  test "switches selected root to admin" do
    admin_root = RecordingStudio::Recording.unscoped.find_by!(
      recordable_type: "RecordingStudioAdmin::Admin",
      parent_recording_id: nil
    )

    post switch_root_recordings_path, params: { root_recording_id: admin_root.id }

    assert_redirected_to root_path

    follow_redirect!

    assert_response :success
    assert_includes response.body, "2 total groups"
    assert_not_includes response.body, "Studio launch plan"
  end

  test "switches between workspace roots" do
    second_workspace = Workspace.create!(name: "Second Workspace")
    second_workspace_root = RecordingStudio::Recording.unscoped.create!(
      recordable: second_workspace,
      parent_recording_id: nil
    )

    post switch_root_recordings_path, params: { root_recording_id: second_workspace_root.id }

    assert_redirected_to root_path

    follow_redirect!

    assert_response :success
    assert_includes response.body, "2 total groups"
    assert_not_includes response.body, "Studio launch plan"
  end

  test "home page count excludes groups without capabilities" do
    workspace_root = RecordingStudio::Recording.unscoped.find_by!(
      recordable_type: "Workspace",
      parent_recording_id: nil
    )

    RecordingStudioCategorisable.configuration.expected_category_groups["color"] = {
      key: "color",
      name: "Color",
      root_recordable_types: ["Workspace"]
    }

    workspace_root.record(
      RecordingStudioCategorisable::CategoryGroup,
      parent_recording: workspace_root
    ) do |group|
      group.name = "Color"
      group.key = "color"
    end

    get root_path

    assert_response :success
    assert_includes response.body, "2 total groups"
    assert_not_includes response.body, "3 total groups"
  end

  test "admin user can access categories on admin root" do
    admin_root = RecordingStudio::Recording.unscoped.find_by!(
      recordable_type: "RecordingStudioAdmin::Admin",
      parent_recording_id: nil
    )

    post switch_root_recordings_path, params: { root_recording_id: admin_root.id }
    assert_redirected_to root_path

    get "/recording_studio_categorisable"
    assert_redirected_to "/recording_studio_categorisable/category_groups"

    follow_redirect!

    assert_response :success
    assert_not_includes response.body, "You are not authorized to manage categories"
  end

  test "admin root page-status group edit is read only when all group fields are disabled" do
    admin_root = RecordingStudio::Recording.unscoped.find_by!(
      recordable_type: "RecordingStudioAdmin::Admin",
      parent_recording_id: nil
    )
    page_status_group = admin_root.recordings_query(
      include_children: true,
      type: RecordingStudioCategorisable::CategoryGroup
    ).includes(:recordable).to_a.find { |recording| recording.recordable&.key == "page-status" }

    post switch_root_recordings_path, params: { root_recording_id: admin_root.id }
    assert_redirected_to root_path

    get "/recording_studio_categorisable/category_groups/#{page_status_group.id}/edit"

    assert_response :success
    assert_includes response.body, "This category group is read-only in the current scope"
    assert_not_includes response.body, 'name="category_group[name]"'
    assert_not_includes response.body, 'name="category_group[key]"'
    assert_not_includes response.body, 'name="category_group[description]"'
    assert_not_includes response.body, 'name="category_group[parent_recording_id]"'
    assert_not_includes response.body, ">Save<"
  end
end
