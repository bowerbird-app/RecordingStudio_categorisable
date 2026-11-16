# frozen_string_literal: true

require "test_helper"

class CategoriesFlowTest < ActionDispatch::IntegrationTest
  BROWSER = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
            "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

  setup do
    @user = User.create!(
      email: "flow-#{SecureRandom.hex(4)}@example.com",
      password: "Password",
      password_confirmation: "Password"
    )
    Current.actor = @user
    workspace = Workspace.create!(name: "Flow #{SecureRandom.hex(4)}")
    @root = RecordingStudio.create_root_recording!(workspace, actor: @user)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: @root, actor: @user)
    raise result.error if result.failure?

    project = Project.create!(name: "Launch notes")
    @project_recording = @root.record(project, actor: @user, parent_recording: @root)
    @news = RecordingStudioCategorisable.record_category(parent_recording: @root, name: "News", actor: @user)
    post user_session_path, params: { user: { email: @user.email, password: "Password" } },
                            headers: { "User-Agent" => BROWSER }
  end

  test "the list, picker, and filter screens render" do
    get "/categories", headers: { "User-Agent" => BROWSER }
    assert_response :success
    assert_includes response.body, "News"

    get "/categories/new", headers: { "User-Agent" => BROWSER }
    assert_response :success
    assert_includes response.body, "Add a category"

    get "/projects/#{@project_recording.id}", headers: { "User-Agent" => BROWSER }
    assert_response :success
    assert_includes response.body, "Category"

    patch "/categories/recordings/#{@project_recording.id}/category",
          params: { category_recording_id: @news.id },
          headers: { "User-Agent" => BROWSER }
    assert_redirected_to "/categories/recordings/#{@project_recording.id}/category/edit"

    get "/categories/#{@news.id}/recordings", headers: { "User-Agent" => BROWSER }
    assert_response :success
    assert_includes response.body, "Launch notes"
  end
end
