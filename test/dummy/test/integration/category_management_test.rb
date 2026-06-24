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

  test "category group show hides item actions when item capabilities are disabled" do
    topics_recording = latest_visible_group_recording_for("page-topics")
    topic_item_recording = latest_visible_item_recording_for(topics_recording, "product")

    get "/recording_studio_categorisable/category_groups/#{topics_recording.id}"

    assert_response :success
    assert_not_includes(
      response.body,
      "/recording_studio_categorisable/category_groups/#{topics_recording.id}/category_items/new"
    )
    assert_not_includes(
      response.body,
      "/recording_studio_categorisable/category_groups/#{topics_recording.id}/category_items/#{topic_item_recording.id}/edit"
    )
    assert_not_includes(
      response.body,
      "/recording_studio_categorisable/category_groups/#{topics_recording.id}/category_items/#{topic_item_recording.id}"
    )
  end

  test "viewer access returns forbidden" do
    sign_out :user
    sign_in User.find_by!(email: "viewer@admin.com")

    get "/recording_studio_categorisable"

    assert_response :forbidden
    assert_includes response.body, "You are not authorized to manage categories"
  end

  test "viewer access can manage configured category group when capability access is view" do
    RecordingStudioCategorisable.configure do |config|
      config.enable_category_group(
        key: "page-status",
        name: "Page Status",
        access: :view,
        allow: { rename: true, update_description: false, move: false, update_key: false }
      )
    end

    sign_out :user
    sign_in User.find_by!(email: "viewer@admin.com")

    get "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}/edit"

    assert_response :success
    assert_includes response.body, "Edit category group"
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

  test "category item create auto-generates key when key is omitted" do
    post "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}/category_items", params: {
      category_item: {
        name: "Needs Generated Key",
        description: "Created without key field",
        position: 999
      }
    }

    assert_redirected_to "/recording_studio_categorisable/category_groups/#{@status_group_recording.id}"

    created_item = @status_group_recording
      .child_recordings
      .of_type(RecordingStudioCategorisable::CategoryItem)
      .includes(:recordable)
      .to_a
      .map(&:recordable)
      .find { |item| item.name == "Needs Generated Key" }

    refute_nil created_item
    assert_equal "needs-generated-key", created_item.key
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

  test "category groups index hides edit when capability is missing for a key" do
    status_recording = latest_visible_group_recording_for("page-status")
    RecordingStudioCategorisable.configuration.category_group_capabilities.delete("page-status")

    get "/recording_studio_categorisable/category_groups"

    assert_response :success
    assert_not_includes(
      response.body,
      "/recording_studio_categorisable/category_groups/#{status_recording.id}/edit"
    )
  end

  test "category groups index hides edit when all allow flags are false" do
    status_recording = latest_visible_group_recording_for("page-status")
    topics_recording = latest_visible_group_recording_for("page-topics")

    RecordingStudioCategorisable.configure do |config|
      config.enable_category_group(
        key: "page-topics",
        name: "Page Topics",
        root_recordable_type: "RecordingStudioAdmin::Admin",
        allow: { rename: true, reorder: false, move: true, update_description: true, update_key: true }
      )
    end

    get "/recording_studio_categorisable/category_groups"

    assert_response :success
    assert_includes(
      response.body,
      "/recording_studio_categorisable/category_groups/#{status_recording.id}/edit"
    )
    assert_not_includes(
      response.body,
      "/recording_studio_categorisable/category_groups/#{topics_recording.id}/edit"
    )
  end

  test "category groups index hides groups that only exist in definitions" do
    RecordingStudioCategorisable.configuration.expected_category_groups["color"] = {
      key: "color",
      name: "Color",
      root_recordable_types: [@root_recording.recordable_type]
    }

    color_recording = @root_recording.record(
      RecordingStudioCategorisable::CategoryGroup,
      parent_recording: @root_recording
    ) do |group|
      group.name = "Color"
      group.key = "color"
    end

    get "/recording_studio_categorisable/category_groups"

    assert_response :success
    assert_not_includes(
      response.body,
      "/recording_studio_categorisable/category_groups/#{color_recording.id}"
    )
    assert_not_includes response.body, ">Color<"
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

  private

  def latest_visible_group_recording_for(key)
    @root_recording
      .recordings_query(include_children: true, type: RecordingStudioCategorisable::CategoryGroup)
      .where(trashed_at: nil)
      .includes(:recordable)
      .to_a
      .select { |recording| recording.recordable&.key == key }
      .max_by(&:created_at)
  end

  def latest_visible_item_recording_for(group_recording, key)
    group_recording
      .child_recordings
      .of_type(RecordingStudioCategorisable::CategoryItem)
      .where(trashed_at: nil)
      .includes(:recordable)
      .to_a
      .select { |recording| recording.recordable&.key == key }
      .max_by(&:created_at)
  end
end
