# frozen_string_literal: true

require "test_helper"

class CapabilitiesTest < Minitest::Test
  def setup
    @original_configuration = RecordingStudioCategorisable.instance_variable_get(:@configuration)
    RecordingStudioCategorisable.instance_variable_set(
      :@configuration,
      RecordingStudioCategorisable::Configuration.new
    )
  end

  def teardown
    RecordingStudioCategorisable.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_category_group_enabled_registers_key_scoped_capability
    RecordingStudioCategorisable::Capabilities::CategoryGroup.enabled(
      key: "page-status",
      name: "Page Status",
      allow: { rename: true, reorder: true }
    )

    capability = RecordingStudioCategorisable.configuration.category_group_capabilities.fetch("page-status")

    assert_equal "Page Status", capability[:name]
    assert_equal true, capability.dig(:allow, :rename)
    assert_equal true, capability.dig(:allow, :reorder)
    assert_equal false, capability.dig(:allow, :update_key)
  end

  def test_category_items_enabled_registers_group_scoped_capability
    RecordingStudioCategorisable::Capabilities::CategoryItems.enabled(
      group_key: "page-status",
      allow: { create: true, delete: true }
    )

    capability = RecordingStudioCategorisable.configuration.category_item_capabilities.fetch("page-status")

    assert_equal true, capability.dig(:allow, :create)
    assert_equal true, capability.dig(:allow, :delete)
    assert_equal false, capability.dig(:allow, :update_name)
  end

  def test_reference_enabled_registers_field_and_reference_capability
    page_class = Struct.new(:title)
    Object.const_set(:CapabilitiesPage, page_class)

    RecordingStudioCategorisable::Capabilities::Reference.enabled(
      recordable: page_class,
      attribute_name: :status_category_item_recording_id,
      category_group_key: "page-status",
      selection: :single,
      label: "Status"
    )

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