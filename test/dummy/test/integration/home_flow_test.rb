# frozen_string_literal: true

require "test_helper"

class HomeFlowTest < ActionDispatch::IntegrationTest
  test "home requires authentication and renders workspace details for signed-in users" do
    user = create_user(email: "admin@example.com")
    workspace = create_workspace(name: "Studio Workspace")
    root_recording = create_root_recording(recordable: workspace)

    Current.actor = user
    grant_root_access!(actor: user, root_recording: root_recording)
    Current.reset

    get "/"
    assert_redirected_to new_user_session_path

    sign_in user
    get "/"

    assert_response :success
    assert_includes response.body, "Studio Workspace"
    assert_includes response.body, root_recording.id
  end
end
