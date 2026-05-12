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
end
