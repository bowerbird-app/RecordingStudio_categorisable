# frozen_string_literal: true

require "test_helper"

class RecordingStudioCategorisableTest < Minitest::Test
  def test_version_exists
    refute_nil ::RecordingStudioCategorisable::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioCategorisable::Engine
  end

  def test_dummy_sidebar_includes_categories_and_pages_links
    sidebar_path = File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__)
    sidebar_source = File.read(sidebar_path)

    assert_includes sidebar_source, "/recording_studio_categorisable"
    assert_includes sidebar_source, "/pages"
  end

  def test_dummy_home_page_mentions_category_and_page_flows
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "Categories mount"
    assert_includes view_source, "Page editor"
    assert_includes view_source, "Seeded pages"
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
end
