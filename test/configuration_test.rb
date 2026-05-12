# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
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

  def test_configure_without_block_is_safe
    RecordingStudioCategorisable.configure

    assert_kind_of RecordingStudioCategorisable::Configuration, RecordingStudioCategorisable.configuration
  end
end
