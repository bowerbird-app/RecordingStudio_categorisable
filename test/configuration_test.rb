# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioCategorisable::Configuration.new
  end

  def test_holder_types_are_normalized
    @configuration.category_holder_types = ["Workspace", "Workspace", nil]

    assert_equal ["Workspace"], @configuration.category_holder_types
  end

  def test_hooks_are_cores
    assert_instance_of RecordingStudio::Hooks, @configuration.hooks
  end
end
