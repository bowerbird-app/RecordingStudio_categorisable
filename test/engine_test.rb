# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def teardown
    RecordingStudioCategorisable.configuration.hooks.clear!
  end

  def test_a_model_extension_registered_by_class_name_is_applied
    model = Class.new
    model.define_singleton_method(:name) { "Project" }
    RecordingStudioCategorisable.configuration.hooks.extend_model(:Project) do
      def labelled
        "extended"
      end
    end

    RecordingStudioCategorisable::Engine.apply_model_extensions(model)

    assert_equal "extended", model.new.labelled
  end
end
