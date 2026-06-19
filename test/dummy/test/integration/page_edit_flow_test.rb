require "test_helper"

class PageEditFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.find_by!(email: "admin@admin.com")
    @root_recording = RecordingStudio::Recording.unscoped.find_by!(parent_recording_id: nil, recordable_type: "Workspace")
    @page_recording = @root_recording.recordings_query(type: Page).includes(:recordable).first
    @status_group_recording = @root_recording.recordings_query(
      include_children: true,
      type: RecordingStudioCategorisable::CategoryGroup
    ).includes(:recordable).find { |recording| recording.recordable.slug == "page-status" }
    @topics_group_recording = @root_recording.recordings_query(
      include_children: true,
      type: RecordingStudioCategorisable::CategoryGroup
    ).includes(:recordable).find { |recording| recording.recordable.slug == "page-topics" }
  end

  test "edit form renders categorisable fields as searchable FlatPack selects" do
    get "/pages/#{@page_recording.id}/edit"

    assert_response :success
    assert_select "[data-controller='flat-pack--select']", 2
    assert_select "[data-flat-pack--select-searchable-value='true']", 2
    assert_select "[data-flat-pack--select-multiple-value='false']", 1
    assert_select "[data-flat-pack--select-multiple-value='true']", 1
    assert_select "input[type='hidden'][name='page[status_category_item_recording_id]']", 1
    assert_select "input[type='hidden'][name='page[topic_category_item_recording_ids][]']"
  end

  test "editing a page revises the recording and saves category item recording ids" do
    draft_item_recording = @status_group_recording.child_recordings
                           .of_type(RecordingStudioCategorisable::CategoryItem)
                           .includes(:recordable)
                           .find { |recording| recording.recordable.slug == "draft" }
    launch_item_recording = @topics_group_recording.child_recordings
                           .of_type(RecordingStudioCategorisable::CategoryItem)
                           .includes(:recordable)
                           .find { |recording| recording.recordable.slug == "launch" }
    previous_recordable_id = @page_recording.recordable_id

    patch "/pages/#{@page_recording.id}", params: {
      page: {
        title: "Updated studio launch plan",
        body: "Revised body copy.",
        status_category_item_recording_id: draft_item_recording.id,
        topic_category_item_recording_ids: [launch_item_recording.id]
      }
    }

    assert_redirected_to "/pages"

    @page_recording.reload

    refute_equal previous_recordable_id, @page_recording.recordable_id
    assert_equal "Updated studio launch plan", @page_recording.recordable.title
    assert_equal draft_item_recording.id, @page_recording.recordable.status_category_item_recording_id
    assert_equal [launch_item_recording.id], @page_recording.recordable.topic_category_item_recording_ids
  end

  test "invalid page updates keep submitting to the update route" do
    patch "/pages/#{@page_recording.id}", params: {
      page: {
        title: "",
        body: @page_recording.recordable.body,
        status_category_item_recording_id:
          @page_recording.recordable.status_category_item_recording_id,
        topic_category_item_recording_ids:
          @page_recording.recordable.topic_category_item_recording_ids
      }
    }

    assert_response :unprocessable_entity
    assert_match(%r{action="/pages/#{@page_recording.id}"}, response.body)
  end
end
