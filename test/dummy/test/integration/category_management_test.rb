require "test_helper"

class CategoryManagementTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.find_by!(email: "admin@admin.com")
    @root_recording = RecordingStudio::Recording.unscoped.find_by!(parent_recording_id: nil, recordable_type: "Workspace")
    @status_group_recording = @root_recording.recordings_query(
      include_children: true,
      type: RecordingStudioCategorisable::CategoryGroup
    ).includes(:recordable).find { |recording| recording.recordable.slug == "page-status" }
    @published_item_recording = @status_group_recording.child_recordings
                               .of_type(RecordingStudioCategorisable::CategoryItem)
                               .includes(:recordable)
                               .find { |recording| recording.recordable.slug == "published" }
  end

  test "category item deletion is blocked while used by a page" do
    delete "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}/category_items/#{@published_item_recording.id}"

    assert_redirected_to "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}"
    assert RecordingStudio::Recording.exists?(@published_item_recording.id)
  end

  test "category group deletion is blocked while a descendant item is in use" do
    nested_group_recording = @root_recording.record(
      RecordingStudioCategorisable::CategoryGroup,
      parent_recording: @status_group_recording
    ) do |group|
      group.name = "Nested status"
      group.slug = "nested-status"
    end
    nested_item_recording = @root_recording.record(
      RecordingStudioCategorisable::CategoryItem,
      parent_recording: nested_group_recording
    ) do |item|
      item.name = "Blocked status"
      item.slug = "blocked-status"
      item.position = 99
    end
    page_recording = @root_recording.recordings_query(type: Page).includes(:recordable).first

    @root_recording.revise(page_recording) do |page|
      page.status_category_item_recording_id = nested_item_recording.id
    end

    delete "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}"

    assert_redirected_to "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}"
    assert RecordingStudio::Recording.exists?(@status_group_recording.id)
  end

  test "duplicate category group slugs are rejected within a root" do
    post "/recording_studio_categorisable/category_groups", params: {
      category_group: {
        name: "Duplicate status",
        slug: "page-status",
        parent_recording_id: @root_recording.id
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "has already been taken within this root"
  end
end
