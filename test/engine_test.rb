# frozen_string_literal: true

require "test_helper"

unless Object.const_defined?(:ActiveRecord)
  module ::ActiveRecord
    class Base
      class << self
        attr_reader :connection
      end
    end
  end
end

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
    declarations = []
    configuration = Struct.new(:recordable_types).new(%w[Workspace Page])
    recording_studio_module.define_singleton_method(:configuration) do
      configuration
    end
    recording_studio_module.define_singleton_method(:register_recordable_type) do |type_name|
      calls << type_name
    end
    Object.const_set(:RecordingStudio, recording_studio_module)
    defined_group_class = RecordingStudioCategorisable.const_defined?(:CategoryGroup, false)
    defined_item_class = RecordingStudioCategorisable.const_defined?(:CategoryItem, false)
    RecordingStudioCategorisable.const_set(:CategoryGroup, Class.new) unless defined_group_class
    RecordingStudioCategorisable.const_set(:CategoryItem, Class.new) unless defined_item_class

    to_prepare_block = nil
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_block = block
    end

    RecordingStudioCategorisable::CategoryGroup.define_singleton_method(:recording_studio_recordable) do |**attributes|
      declarations << [:group, attributes]
    end
    RecordingStudioCategorisable::CategoryItem.define_singleton_method(:recording_studio_recordable) do |**attributes|
      declarations << [:item, attributes]
    end

    RecordingStudioCategorisable::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_categorisable.register_recordable_types").block.call
    end

    to_prepare_block.call

    assert_equal [
      "RecordingStudioCategorisable::CategoryGroup",
      "RecordingStudioCategorisable::CategoryItem"
    ], calls
    assert_equal %i[group item], declarations.map(&:first)
  ensure
    class << RecordingStudioCategorisable::CategoryGroup
      remove_method :recording_studio_recordable if method_defined?(:recording_studio_recordable)
    end
    class << RecordingStudioCategorisable::CategoryItem
      remove_method :recording_studio_recordable if method_defined?(:recording_studio_recordable)
    end
    RecordingStudioCategorisable.send(:remove_const, :CategoryGroup) unless defined_group_class
    RecordingStudioCategorisable.send(:remove_const, :CategoryItem) unless defined_item_class
  end

  def test_seed_categories_from_config_filters_definitions_per_root_type
    RecordingStudioCategorisable.category_definitions = [
      { group_key: "page-status", group_name: "Page Status" },
      { group_key: "color", group_name: "Color" }
    ]
    RecordingStudioCategorisable.configuration.enable_category_group(
      key: "page-status",
      name: "Page Status",
      root_recordable_type: "Workspace"
    )
    RecordingStudioCategorisable.configuration.enable_category_group(
      key: "color",
      name: "Color",
      root_recordable_type: "RecordingStudioAdmin::Admin"
    )

    workspace_root = Struct.new(:recordable_type).new("Workspace")
    root_recordings = Object.new
    root_recordings.define_singleton_method(:empty?) { false }
    root_recordings.define_singleton_method(:find_each) do |&block|
      [workspace_root].each(&block)
    end

    recording_studio_module = Module.new
    recording_class = Class.new
    recording_class.define_singleton_method(:where) do |parent_recording_id:|
      root_recordings
    end
    recording_studio_module.const_set(:Recording, recording_class)
    Object.const_set(:RecordingStudio, recording_studio_module)

    connection = Object.new
    connection.define_singleton_method(:table_exists?) do |table_name|
      table_name == :recording_studio_recordings
    end

    seed_calls = []
    to_prepare_block = nil
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_block = block
    end

    RecordingStudioCategorisable::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_categorisable.seed_categories_from_config").block.call
    end

    ActiveRecord::Base.stub(:connection, connection) do
      RecordingStudioCategorisable::Services::SeedCategories.stub(:call, lambda { |root_recording:, category_definitions:|
        seed_calls << [root_recording.recordable_type, category_definitions.map { |definition| definition[:group_key] }]
      }) do
        to_prepare_block.call
      end
    end

    assert_equal [["Workspace", ["page-status"]]], seed_calls
  end

  private

  def find_initializer(name)
    RecordingStudioCategorisable::Engine.initializers.find { |initializer| initializer.name == name }
  end
end
