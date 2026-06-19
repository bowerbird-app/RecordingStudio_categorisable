require "test_helper"

class GuideNavigationTest < ActionDispatch::IntegrationTest
  setup do
    sign_in User.find_by!(email: "admin@admin.com")
  end

  test "sidebar includes categorisable guide links" do
    get "/"

    assert_response :success
    assert_select "a[href='/install']"
    assert_select "a[href='/config']"
    assert_select "a[href='/methods']"
    assert_select "a[href='/components']"
    assert_select "a[href='/recording-tree']"
  end

  test "guide pages render" do
    {
      "/install" => "Install",
      "/config" => "Config",
      "/methods" => "Methods",
      "/components" => "Components"
    }.each do |path, title|
      get path

      assert_response :success
      assert_select "h1", text: title
    end
  end

  test "recording tree page renders flatpack tree" do
    get "/recording-tree"

    assert_response :success
    assert_select "h1", text: "Recording Tree"
    assert_select "[role='tree']", 1
    assert_select "[role='treeitem']"
    assert_includes response.body, "Access - admin - admin@admin.com"
    assert_includes response.body, "Access - view - viewer@admin.com"
  end
end
