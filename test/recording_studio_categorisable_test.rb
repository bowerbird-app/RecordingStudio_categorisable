# frozen_string_literal: true

require "test_helper"

class RecordingStudioCategorisableTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_version_exists
    refute_nil ::RecordingStudioCategorisable::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioCategorisable::Engine
  end

  def test_engine_has_expected_name
    assert_equal "recording_studio_categorisable", RecordingStudioCategorisable::Engine.engine_name
  end

  def test_configuration_exists
    assert_kind_of RecordingStudioCategorisable::Configuration, RecordingStudioCategorisable.configuration
  end

  def test_can_configure_via_block
    original_config = RecordingStudioCategorisable.configuration

    RecordingStudioCategorisable.configure do |config|
      assert_equal original_config, config
    end
  end

  def test_feature_files_exist
    expected_files = %w[
      app/controllers/recording_studio_categorisable/application_controller.rb
      app/controllers/recording_studio_categorisable/category_groups_controller.rb
      app/controllers/recording_studio_categorisable/category_items_controller.rb
      app/controllers/recording_studio_categorisable/category_assignments_controller.rb
      app/models/recording_studio_categorisable/category_group.rb
      app/models/recording_studio_categorisable/category_item.rb
      app/models/recording_studio_categorisable/category_assignment.rb
      app/models/recording_studio_categorisable/categorisable.rb
    ]

    expected_files.each do |relative_path|
      assert File.exist?(File.join(ROOT, relative_path)), "Expected #{relative_path} to exist"
    end
  end
end
