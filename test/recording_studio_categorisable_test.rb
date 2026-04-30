# frozen_string_literal: true

require "test_helper"

class RecordingStudioCategorisableTest < Minitest::Test
  def test_version_exists
    refute_nil ::RecordingStudioCategorisable::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioCategorisable::Engine
  end

  def test_engine_is_isolated
    assert_equal RecordingStudioCategorisable, RecordingStudioCategorisable::Engine.isolated_namespace
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

  def test_recordable_models_exist
    assert defined?(RecordingStudioCategorisable::CategoryGroup)
    assert defined?(RecordingStudioCategorisable::CategoryItem)
    assert defined?(RecordingStudioCategorisable::CategoryAssignment)
  end

  def test_controllers_exist
    assert defined?(RecordingStudioCategorisable::ApplicationController)
    assert defined?(RecordingStudioCategorisable::CategoryGroupsController)
    assert defined?(RecordingStudioCategorisable::CategoryItemsController)
    assert defined?(RecordingStudioCategorisable::CategoryAssignmentsController)
  end
end
