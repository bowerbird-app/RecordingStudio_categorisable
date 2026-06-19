require "test_helper"

class BriefEditFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.find_by!(email: "admin@admin.com")
    @root_recording = RecordingStudio::Recording.unscoped.find_by!(parent_recording_id: nil, recordable_type: "Workspace")
    @brief_recording = @root_recording.recordings_query(type: Brief).includes(:recordable).first
    @status_group_recording = @root_recording.recordings_query(
      include_children: true,
      type: RecordingStudioCategorisable::CategoryGroup
    ).includes(:recordable).find { |recording| recording.recordable.slug == "page-status" }
  end

  test "edit form renders a single-select categorisable field" do
    get "/briefs/#{@brief_recording.id}/edit"

    assert_response :success
    assert_select "[data-controller='flat-pack--select']", 1
    assert_select "[data-flat-pack--select-searchable-value='true']", 1
    assert_select "[data-flat-pack--select-multiple-value='false']", 1
    assert_select "input[type='hidden'][name='brief[status_category_item_recording_id]']", 1
  end

  test "editing a brief revises the recording and saves the selected status" do
    draft_item_recording = @status_group_recording.child_recordings
                           .of_type(RecordingStudioCategorisable::CategoryItem)
                           .includes(:recordable)
                           .find { |recording| recording.recordable.slug == "draft" }
    previous_recordable_id = @brief_recording.recordable_id

    patch "/briefs/#{@brief_recording.id}", params: {
      brief: {
        title: "Updated studio brief",
        body: "Revised brief body copy.",
        status_category_item_recording_id: draft_item_recording.id
      }
    }

    assert_redirected_to "/briefs"

    @brief_recording.reload

    refute_equal previous_recordable_id, @brief_recording.recordable_id
    assert_equal "Updated studio brief", @brief_recording.recordable.title
    assert_equal draft_item_recording.id, @brief_recording.recordable.status_category_item_recording_id
  end
end
