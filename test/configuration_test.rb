# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioCategorisable::Configuration.new
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(api_key: "abc123", timeout: 9, enable_feature_x: true)

    assert_equal "abc123", @configuration.api_key
    assert_equal 9, @configuration.timeout
    assert_equal true, @configuration.enable_feature_x
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", timeout: 7)

    refute_respond_to @configuration, :unknown_key
    assert_equal 7, @configuration.timeout
  end

  def test_merge_with_non_enumerable_is_noop
    @configuration.api_key = nil
    @configuration.timeout = nil
    @configuration.enable_feature_x = nil

    @configuration.merge!(nil)

    assert_nil @configuration.api_key
    assert_nil @configuration.timeout
    assert_nil @configuration.enable_feature_x
  end

  def test_to_h_reports_registered_hook_counts_and_resolver_presence
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
    assert_equal false, result.fetch(:root_recording_resolver)

    @configuration.root_recording_resolver = ->(controller:) { controller }

    assert_equal true, @configuration.to_h.fetch(:root_recording_resolver)
  end

  def test_configure_without_block_is_safe
    RecordingStudioCategorisable.configure

    assert_kind_of RecordingStudioCategorisable::Configuration, RecordingStudioCategorisable.configuration
  end
end
