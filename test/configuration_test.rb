# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  class ControllerDouble
    attr_writer :performed

    def initialize(performed)
      @performed = performed
    end

    def performed?
      @performed
    end
  end

  def setup
    @configuration = RecordingStudioCategorisable::Configuration.new
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(ui_title: "Taxonomy")

    assert_equal "Taxonomy", @configuration.ui_title
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", ui_title: "Updated")

    refute_respond_to @configuration, :unknown_key
    assert_equal "Updated", @configuration.ui_title
  end

  def test_register_categorisable_reuses_registration_per_type
    first_registration = @configuration.register_categorisable("Page")
    page_class = Struct.new(:title)
    Object.const_set(:Page, page_class)
    second_registration = @configuration.register_categorisable(page_class)

    assert_same first_registration, second_registration
  ensure
    Object.send(:remove_const, :Page) if Object.const_defined?(:Page)
  end

  def test_to_h_reports_registered_hook_counts_and_registration_names
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.register_categorisable("Page")

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal ["Page"], result.fetch(:categorisable_registrations)
  end

  def test_authorize_raises_when_no_authorization_resolver_is_configured
    error = assert_raises(RecordingStudioCategorisable::MissingAuthorizationError) do
      @configuration.authorize!(Object.new)
    end

    assert_match("Authorization is required", error.message)
  end

  def test_resolve_root_recording_defaults_to_nil
    assert_nil @configuration.resolve_root_recording(Object.new)
  end

  def test_configure_without_block_is_safe
    RecordingStudioCategorisable.configure

    assert_kind_of RecordingStudioCategorisable::Configuration, RecordingStudioCategorisable.configuration
  end

  def test_handle_unauthorized_returns_false_when_no_handler_is_configured
    controller = ControllerDouble.new(false)

    refute @configuration.handle_unauthorized(controller, StandardError.new("nope"))
  end

  def test_handle_unauthorized_executes_handler_and_reports_if_response_was_performed
    called = false
    controller = ControllerDouble.new(true)

    @configuration.unauthorized_response_handler = lambda do |passed_controller, passed_exception|
      called = true
      assert_same controller, passed_controller
      assert_equal "blocked", passed_exception.message
    end

    handled = @configuration.handle_unauthorized(controller, StandardError.new("blocked"))

    assert called
    assert handled
  end

  def test_category_definitions_for_filters_to_enabled_groups_for_root_type
    @configuration.category_definitions = [
      { key: "page-status", name: "Page Status" },
      { key: "color", name: "Color" },
      { key: "orphaned", name: "Orphaned" }
    ]
    @configuration.enable_category_group(
      key: "page-status",
      name: "Page Status",
      root_recordable_type: "Workspace"
    )
    @configuration.enable_category_group(
      key: "color",
      name: "Color",
      root_recordable_type: "RecordingStudioAdmin::Admin"
    )

    definitions = @configuration.category_definitions_for(root_recordable_type: "Workspace")

    assert_equal ["page-status"], definitions.map { |definition| definition[:key] }
  end
end
