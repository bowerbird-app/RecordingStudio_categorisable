# frozen_string_literal: true

require "test_helper"

class CapabilitiesTest < Minitest::Test
  def setup
    @recording_studio_stubbed = false
    bootstrap_recording_studio_if_missing!

    @original_configuration = RecordingStudioCategorisable.instance_variable_get(:@configuration)
    RecordingStudioCategorisable.instance_variable_set(
      :@configuration,
      RecordingStudioCategorisable::Configuration.new
    )

    configuration = RecordingStudio.configuration

    if configuration.respond_to?(:capability_options_store)
      @original_capabilities = configuration.capabilities
      @original_capability_options = configuration.capability_options_store
      configuration.capabilities = Hash.new { |hash, key| hash[key] = Set.new }
      configuration.capability_options_store = {}
    else
      @original_capabilities = configuration.instance_variable_get(:@capabilities)
      @original_capability_options = configuration.instance_variable_get(:@capability_options)
      configuration.instance_variable_set(:@capabilities, {})
      configuration.instance_variable_set(:@capability_options, {})
    end
  end

  def teardown
    configuration = RecordingStudio.configuration

    if configuration.respond_to?(:capability_options_store)
      configuration.capabilities = @original_capabilities
      configuration.capability_options_store = @original_capability_options
    else
      configuration.instance_variable_set(:@capabilities, @original_capabilities)
      configuration.instance_variable_set(:@capability_options, @original_capability_options)
    end

    RecordingStudioCategorisable.instance_variable_set(:@configuration, @original_configuration)

    Object.send(:remove_const, :RecordingStudio) if @recording_studio_stubbed && Object.const_defined?(:RecordingStudio)
  end

  def bootstrap_recording_studio_if_missing!
    return if Object.const_defined?(:RecordingStudio)

    recording_studio_module = Module.new
    recording_studio_module.define_singleton_method(:configuration) do
      @configuration ||= Struct.new(:capabilities, :capability_options_store) do
        def initialize
          super(Hash.new { |hash, key| hash[key] = Set.new }, {})
        end

        def enable_capability(capability, on:)
          type_name = on.is_a?(Class) ? on.name : on.to_s
          capabilities[type_name] << capability.to_sym
        end

        def set_capability_options(capability, on:, **options)
          type_name = on.is_a?(Class) ? on.name : on.to_s
          capability_options_store[[capability.to_sym, type_name]] = options
        end

        def capability_options(capability, for_type:)
          type_name = for_type.is_a?(Class) ? for_type.name : for_type.to_s
          capability_options_store[[capability.to_sym, type_name]]
        end
      end.new
    end

    recording_studio_module.define_singleton_method(:enable_capability) do |capability, on:|
      configuration.enable_capability(capability, on: on)
    end

    recording_studio_module.define_singleton_method(:set_capability_options) do |capability, on:, **options|
      configuration.set_capability_options(capability, on: on, **options)
    end

    recording_studio_module.define_singleton_method(:capability_options) do |capability, **kwargs|
      configuration.capability_options(capability, for_type: kwargs[:for] || kwargs[:for_type])
    end

    Object.const_set(:RecordingStudio, recording_studio_module)
    @recording_studio_stubbed = true
  end

  def test_category_group_enabled_registers_key_scoped_capability
    RecordingStudio.enable_capability(:categorisable, on: "Workspace")
    RecordingStudio.set_capability_options(
      :categorisable,
      on: "Workspace",
      category_groups: [
        {
          key: "page-status",
          name: "Page Status",
          allow: { rename: true }
        }
      ]
    )
    RecordingStudioCategorisable::Capabilities::Categorisable.apply_for("Workspace")

    capability = RecordingStudioCategorisable.configuration.category_group_capabilities.fetch("page-status")

    assert_equal "Page Status", capability[:name]
    assert_equal true, capability.dig(:allow, :rename)
    assert_nil capability.dig(:allow, :reorder)
    assert_equal false, capability.dig(:allow, :update_key)
    assert_equal :edit, capability[:access]
  end

  def test_category_group_enabled_allows_custom_access_role
    RecordingStudio.enable_capability(:categorisable, on: "Workspace")
    RecordingStudio.set_capability_options(
      :categorisable,
      on: "Workspace",
      category_groups: [
        {
          key: "page-status",
          name: "Page Status",
          access: :view,
          allow: { rename: true }
        }
      ]
    )
    RecordingStudioCategorisable::Capabilities::Categorisable.apply_for("Workspace")

    capability = RecordingStudioCategorisable.configuration.category_group_capabilities.fetch("page-status")

    assert_equal :view, capability[:access]
  end

  def test_category_group_capability_lookup_prefers_root_scoped_capability
    RecordingStudio.enable_capability(:categorisable, on: "Workspace")
    RecordingStudio.set_capability_options(
      :categorisable,
      on: "Workspace",
      category_groups: [
        {
          key: "page-topics",
          name: "Page Topics",
          root_recordable_type: "Workspace",
          allow: { rename: false }
        }
      ]
    )
    RecordingStudioCategorisable::Capabilities::Categorisable.apply_for("Workspace")

    RecordingStudio.enable_capability(:categorisable, on: "RecordingStudioAdmin::Admin")
    RecordingStudio.set_capability_options(
      :categorisable,
      on: "RecordingStudioAdmin::Admin",
      category_groups: [
        {
          key: "page-topics",
          name: "Page Topics",
          root_recordable_type: "RecordingStudioAdmin::Admin",
          allow: { rename: true }
        }
      ]
    )
    RecordingStudioCategorisable::Capabilities::Categorisable.apply_for("RecordingStudioAdmin::Admin")

    workspace_capability = RecordingStudioCategorisable.configuration.category_group_capability_for(
      "page-topics",
      root_recordable_type: "Workspace"
    )
    admin_capability = RecordingStudioCategorisable.configuration.category_group_capability_for(
      "page-topics",
      root_recordable_type: "RecordingStudioAdmin::Admin"
    )

    assert_equal false, workspace_capability.dig(:allow, :rename)
    assert_equal true, admin_capability.dig(:allow, :rename)
  end

  def test_category_items_enabled_registers_group_scoped_capability
    RecordingStudio.enable_capability(:categorisable, on: "Workspace")
    RecordingStudio.set_capability_options(
      :categorisable,
      on: "Workspace",
      category_items: [
        {
          group_key: "page-status",
          allow: { create: true, delete: true }
        }
      ]
    )
    RecordingStudioCategorisable::Capabilities::Categorisable.apply_for("Workspace")

    capability = RecordingStudioCategorisable.configuration.category_item_capabilities.fetch("page-status")

    assert_equal true, capability.dig(:allow, :create)
    assert_equal true, capability.dig(:allow, :delete)
    assert_equal false, capability.dig(:allow, :update_name)
    assert_equal false, capability.dig(:allow, :update_description)
  end

  def test_category_item_capability_lookup_prefers_root_scoped_capability
    RecordingStudio.enable_capability(:categorisable, on: "Workspace")
    RecordingStudio.set_capability_options(
      :categorisable,
      on: "Workspace",
      category_items: [
        {
          group_key: "page-topics",
          root_recordable_type: "Workspace",
          allow: { create: false }
        }
      ]
    )
    RecordingStudioCategorisable::Capabilities::Categorisable.apply_for("Workspace")

    RecordingStudio.enable_capability(:categorisable, on: "RecordingStudioAdmin::Admin")
    RecordingStudio.set_capability_options(
      :categorisable,
      on: "RecordingStudioAdmin::Admin",
      category_items: [
        {
          group_key: "page-topics",
          root_recordable_type: "RecordingStudioAdmin::Admin",
          allow: { create: true }
        }
      ]
    )
    RecordingStudioCategorisable::Capabilities::Categorisable.apply_for("RecordingStudioAdmin::Admin")

    workspace_capability = RecordingStudioCategorisable.configuration.category_item_capability_for(
      "page-topics",
      root_recordable_type: "Workspace"
    )
    admin_capability = RecordingStudioCategorisable.configuration.category_item_capability_for(
      "page-topics",
      root_recordable_type: "RecordingStudioAdmin::Admin"
    )

    assert_equal false, workspace_capability.dig(:allow, :create)
    assert_equal true, admin_capability.dig(:allow, :create)
  end

  def test_reference_enabled_registers_field_and_reference_capability
    page_class = Struct.new(:title)
    Object.const_set(:CapabilitiesPage, page_class)

    RecordingStudio.enable_capability(:categorisable, on: page_class)
    RecordingStudio.set_capability_options(
      :categorisable,
      on: page_class,
      references: [
        {
          attribute_name: :status_category_item_recording_id,
          category_group_key: "page-status",
          selection: :single,
          label: "Status"
        }
      ]
    )
    RecordingStudioCategorisable::Capabilities::Categorisable.apply_for(page_class)

    registration = RecordingStudioCategorisable.configuration.registration_for(page_class)
    reference = RecordingStudioCategorisable.configuration.reference_capabilities.fetch("CapabilitiesPage").first

    assert_equal :single, registration.field(:status_category_item_recording_id).selection
    assert_equal "page-status", reference[:category_group_key]
    assert_equal :single, reference[:selection]
    assert_equal "Status", reference[:label]
    assert page_class < RecordingStudioCategorisable::Categorisable
  ensure
    Object.send(:remove_const, :CapabilitiesPage) if Object.const_defined?(:CapabilitiesPage)
  end
end
