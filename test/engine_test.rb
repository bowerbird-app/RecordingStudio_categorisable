# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def setup
    @original_configuration = RecordingStudioCategorisable.instance_variable_get(:@configuration)
    RecordingStudioCategorisable.instance_variable_set(:@configuration, RecordingStudioCategorisable::Configuration.new)
  end

  def teardown
    RecordingStudioCategorisable.configuration.hooks.clear!
    RecordingStudioCategorisable.instance_variable_set(:@configuration, @original_configuration)
    Object.send(:remove_const, :RecordingStudio) if Object.const_defined?(:RecordingStudio)
  end

  def test_before_and_after_initialize_initializers_run_hooks
    before_called = false
    after_called = false

    RecordingStudioCategorisable.configuration.hooks.before_initialize { |_engine| before_called = true }
    RecordingStudioCategorisable.configuration.hooks.after_initialize { |_engine| after_called = true }

    find_initializer("recording_studio_categorisable.before_initialize").block.call(Object.new)
    find_initializer("recording_studio_categorisable.after_initialize").block.call(Object.new)

    assert before_called
    assert after_called
  end

  def test_load_config_merges_config_sources_and_runs_on_configuration_hook
    hook_called = false
    hook_payload = nil
    RecordingStudioCategorisable.configuration.hooks.on_configuration do |cfg|
      hook_called = true
      hook_payload = cfg
    end

    xcfg = Struct.new(:recording_studio_categorisable).new({ ui_title: "Configured categories" })
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { ui_title: "From YAML" }
      end
    end.new(app_config)

    find_initializer("recording_studio_categorisable.load_config").block.call(app)

    assert hook_called
    assert_equal RecordingStudioCategorisable.configuration, hook_payload
    assert_equal "Configured categories", RecordingStudioCategorisable.configuration.ui_title
  end

  def test_apply_extension_initializers_register_to_prepare_callbacks
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    RecordingStudioCategorisable::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_categorisable.apply_model_extensions").block.call
      find_initializer("recording_studio_categorisable.apply_controller_extensions").block.call
      find_initializer("recording_studio_categorisable.register_recordable_types").block.call
    end

    assert_equal 3, to_prepare_blocks.size
  end

  def test_apply_model_extensions_adds_registered_methods_once
    model_class = Class.new do
      def self.name
        "ExampleRecord"
      end
    end

    RecordingStudioCategorisable.configuration.hooks.extend_model(:ExampleRecord) do
      def template_extension_method
        :applied
      end
    end

    RecordingStudioCategorisable::Engine.apply_model_extensions(model_class)
    RecordingStudioCategorisable::Engine.apply_model_extensions(model_class)

    assert_equal :applied, model_class.new.template_extension_method
  end

  def test_register_recordable_types_initializer_registers_group_and_item_types
    recording_studio_module = Module.new
    calls = []
    recording_studio_module.define_singleton_method(:register_recordable_type) do |type_name|
      calls << type_name
    end
    Object.const_set(:RecordingStudio, recording_studio_module)

    to_prepare_block = nil
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_block = block
    end

    RecordingStudioCategorisable::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_categorisable.register_recordable_types").block.call
    end

    to_prepare_block.call

    assert_equal [
      "RecordingStudioCategorisable::CategoryGroup",
      "RecordingStudioCategorisable::CategoryItem"
    ], calls
  end

  private

  def find_initializer(name)
    RecordingStudioCategorisable::Engine.initializers.find { |initializer| initializer.name == name }
  end
end
