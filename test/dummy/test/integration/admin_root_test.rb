require "test_helper"

class AdminRootTest < ActionDispatch::IntegrationTest
  test "admin user can open the mounted admin root" do
    sign_in User.find_by!(email: "admin@admin.com")

    get "/admin"

    assert_response :success
    assert_includes response.body, "Admin"
  end

  test "viewer can open the mounted admin root through seeded view access" do
    sign_in User.find_by!(email: "viewer@admin.com")

    get "/admin"

    assert_response :forbidden
  end
end