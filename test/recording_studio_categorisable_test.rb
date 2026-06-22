# frozen_string_literal: true

require "test_helper"

class RecordingStudioCategorisableTest < Minitest::Test
  def test_version_exists
    refute_nil ::RecordingStudioCategorisable::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioCategorisable::Engine
  end

  def test_dummy_sidebar_includes_categories_link
    sidebar_path = File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__)
    sidebar_source = File.read(sidebar_path)

    assert_includes sidebar_source, "/recording_studio_categorisable"
    refute_includes sidebar_source, "/pages"
    refute_includes sidebar_source, "/briefs"
  end

  def test_dummy_home_page_mentions_category_behavior_examples
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "Category behavior examples"
    assert_includes view_source, "Add Page"
    assert_includes view_source, "Add Brief"
    assert_includes view_source, "Recordable"
    assert_includes view_source, "Manage Categories"
    assert_includes view_source, "new_page_path"
    assert_includes view_source, "new_brief_path"
  end

  def test_engine_views_use_flatpack_components
    view_path = File.expand_path("../app/views/recording_studio_categorisable/category_groups/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "FlatPack::PageNav::Component"
    assert_includes view_source, "FlatPack::PageTitle::Component"
    assert_includes view_source, "FlatPack::Table::Component"
    assert_includes view_source, "FlatPack::Button::Component"
    assert_includes view_source, "FlatPack::Badge::Component"
  end

  def test_dummy_methods_page_mentions_useful_categorisable_apis
    view_path = File.expand_path("dummy/app/views/guides/methods.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "recording_studio_category_fields"
    assert_includes view_source, "Page.status_category_item_recording_id"
    assert_includes view_source, "Page.available_category_groups"
    assert_includes view_source, "page.assigned_category_items"
  end
end
