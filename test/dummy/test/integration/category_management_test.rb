require "test_helper"

class CategoryManagementTest < ActionDispatch::IntegrationTest
  setup do
    RecordingStudioCategorisable.configure do |config|
      config.root_recording_resolver = ->(controller) { controller.send(:current_root_recording) }
      config.authorization_resolver = ->(controller) { controller.current_user.present? }
      config.enable_category_group(
        key: "page-status",
        name: "Page Status",
        allow: { rename: true, update_description: true, move: true, update_key: false }
      )
      config.enable_category_items(
        group_key: "page-status",
        allow: { create: true, update_name: true, update_position: true, update_key: false, delete: true }
      )
    end

    sign_in User.find_by!(email: "admin@admin.com")
    @root_recording = RecordingStudio::Recording.unscoped.find_by!(parent_recording_id: nil, recordable_type: "Workspace")
    @status_group_recording = @root_recording.recordings_query(
      include_children: true,
      type: RecordingStudioCategorisable::CategoryGroup
    ).includes(:recordable).to_a.detect { |recording| recording.recordable&.key == "page-status" }
    @topics_group_recording = @root_recording.recordings_query(
      include_children: true,
      type: RecordingStudioCategorisable::CategoryGroup
    ).includes(:recordable).to_a.detect { |recording| recording.recordable&.key == "page-topics" }
    @published_item_recording = @status_group_recording.child_recordings
                               .of_type(RecordingStudioCategorisable::CategoryItem)
                               .includes(:recordable)
                               .to_a
                               .detect { |recording| recording.recordable&.key == "published" }
  end

  test "category item deletion is blocked while used by a page" do
    page_recording = @root_recording.recordings_query(type: Page).includes(:recordable).first
    @root_recording.revise(page_recording) do |page|
      page.status_category_item_recording_id = @published_item_recording.id
    end

    delete "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}/category_items/#{@published_item_recording.id}"

    assert_redirected_to "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}"
    assert RecordingStudio::Recording.exists?(@published_item_recording.id)
  end

  test "deleted seeded category item stays hidden and is not recreated by seeding" do
    removable_item = @root_recording.record(
      RecordingStudioCategorisable::CategoryItem,
      parent_recording: @status_group_recording
    ) do |item|
      item.name = "Temporary"
      item.key = "temporary"
      item.position = 9
    end

    delete "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}/category_items/#{removable_item.id}"

    assert_redirected_to "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}"
    assert_not_nil removable_item.reload.trashed_at

    RecordingStudioCategorisable::Services::SeedCategories.call(
      root_recording: @root_recording,
      category_definitions: [
        {
          key: "page-status",
          name: "Page Status",
          items: [
            { key: "temporary", name: "Temporary", position: 9 }
          ]
        }
      ]
    )

    matches = @status_group_recording.child_recordings.of_type(RecordingStudioCategorisable::CategoryItem)
                 .includes(:recordable)
                 .to_a
                 .select { |recording| recording.recordable&.key == "temporary" }

    assert_equal 1, matches.size
    assert_not_nil matches.first.trashed_at
  end

  test "category item deletion is blocked when delete capability is disabled" do
    RecordingStudioCategorisable.configure do |config|
      config.enable_category_items(
        group_key: "page-status",
        allow: { create: true, update_name: true, update_position: true, update_key: false, delete: false }
      )
    end

    new_item = @root_recording.record(
      RecordingStudioCategorisable::CategoryItem,
      parent_recording: @status_group_recording
    ) do |item|
      item.name = "Temporary"
      item.key = "temporary"
      item.position = 9
    end

    delete "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}/category_items/#{new_item.id}"

    assert_response :forbidden
    assert RecordingStudio::Recording.exists?(new_item.id)
  end

  test "viewer access returns forbidden" do
    sign_out :user
    sign_in User.find_by!(email: "viewer@admin.com")

    get "/recording_studio_categorisable"

    assert_response :forbidden
    assert_includes response.body, "You are not authorized to manage categories"
  end

  test "category group deletion is blocked while a descendant item is in use" do
    nested_group_recording = @root_recording.record(
      RecordingStudioCategorisable::CategoryGroup,
      parent_recording: @status_group_recording
    ) do |group|
      group.name = "Nested status"
      group.key = "nested-status"
    end
    nested_item_recording = @root_recording.record(
      RecordingStudioCategorisable::CategoryItem,
      parent_recording: nested_group_recording
    ) do |item|
      item.name = "Blocked status"
      item.key = "blocked-status"
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

  test "duplicate category group keys are rejected within a root" do
    post "/recording_studio_categorisable/category_groups", params: {
      category_group: {
        name: "Duplicate status",
        key: "page-status",
        parent_recording_id: @root_recording.id
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "has already been taken within this root"
  end

  test "invalid category group updates keep submitting to the update route" do
    patch "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}", params: {
      category_group: {
        name: "",
        key: @status_group_recording.recordable.key,
        description: @status_group_recording.recordable.description,
        parent_recording_id: @root_recording.id
      }
    }

    assert_response :unprocessable_entity
    assert_match(
      %r{action="/recording_studio_categorisable/category_groups/#{@status_group_recording.id}"},
      response.body
    )
  end

  test "category group move is blocked when move capability is disabled" do
    RecordingStudioCategorisable.configure do |config|
      config.enable_category_group(
        key: "page-status",
        name: "Page Status",
        allow: { rename: true, update_description: true, move: false, update_key: false }
      )
    end

    patch "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}", params: {
      category_group: {
        name: @status_group_recording.recordable.name,
        key: @status_group_recording.recordable.key,
        description: @status_group_recording.recordable.description,
        parent_recording_id: @topics_group_recording.id
      }
    }

    assert_response :forbidden
    assert_equal @root_recording.id, @status_group_recording.reload.parent_recording_id
  end

  test "category item updates are allowed when capability enables them" do
    patch(
      "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}/category_items/#{@published_item_recording.id}",
      params: {
        category_item: {
          name: "Published Updated",
          key: @published_item_recording.recordable.key,
          description: @published_item_recording.recordable.description,
          position: @published_item_recording.recordable.position
        }
      }
    )

    assert_redirected_to "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}"
    assert_equal "Published Updated", @published_item_recording.reload.recordable.name
  end

  test "invalid category item updates keep submitting to the update route" do
    patch(
      "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}/category_items/#{@published_item_recording.id}",
      params: {
        category_item: {
          name: "",
          key: @published_item_recording.recordable.key,
          description: @published_item_recording.recordable.description,
          position: @published_item_recording.recordable.position
        }
      }
    )

    assert_response :unprocessable_entity
    assert_match(
      %r{action="/recording_studio_categorisable/category_groups/#{@status_group_recording.id}/category_items/#{@published_item_recording.id}"},
      response.body
    )
  end

  test "category groups cannot be moved under their descendants" do
    nested_group_recording = @root_recording.record(
      RecordingStudioCategorisable::CategoryGroup,
      parent_recording: @status_group_recording
    ) do |group|
      group.name = "Nested status"
      group.key = "nested-status"
    end

    patch "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}", params: {
      category_group: {
        name: @status_group_recording.recordable.name,
        key: @status_group_recording.recordable.key,
        description: @status_group_recording.recordable.description,
        parent_recording_id: nested_group_recording.id
      }
    }

    assert_response :unprocessable_entity
    assert_includes(
      response.body,
      "Category groups cannot be moved under themselves or their descendants"
    )
    assert_equal @root_recording.id, @status_group_recording.reload.parent_recording_id
  end

  test "category group update keeps existing parent when parent is not submitted" do
    nested_group_recording = @root_recording.record(
      RecordingStudioCategorisable::CategoryGroup,
      parent_recording: @status_group_recording
    ) do |group|
      group.name = "Nested status"
      group.key = "nested-status"
    end

    patch "/recording_studio_categorisable/category_groups/#{nested_group_recording.id}", params: {
      category_group: {
        name: "Nested status updated",
        key: "nested-status",
        description: "Updated"
      }
    }

    assert_redirected_to "/recording_studio_categorisable/category_groups/#{nested_group_recording.id}"
    assert_equal @status_group_recording.id, nested_group_recording.reload.parent_recording_id
  end
end
