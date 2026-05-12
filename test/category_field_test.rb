# frozen_string_literal: true

require "test_helper"

class CategoryFieldTest < Minitest::Test
  def test_single_select_normalizes_to_a_single_value
    field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :status_category_item_recording_id,
      selection: :single,
      category_group_slug: "page-status"
    )

    recordable = Struct.new(:status_category_item_recording_id).new("recording-1")

    assert_equal "recording-1", field.read(recordable)
  end

  def test_multiple_select_normalizes_and_deduplicates_values
    field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :topic_category_item_recording_ids,
      selection: :multiple,
      category_group_slug: "page-topics"
    )

    recordable = Struct.new(:topic_category_item_recording_ids).new(["alpha", "", "beta", "alpha"])

    assert_equal %w[alpha beta], field.read(recordable)
  end

  def test_write_uses_custom_writer_when_present
    received_value = nil
    field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :topic_category_item_recording_ids,
      selection: :multiple,
      category_group_slug: "page-topics",
      value_writer: ->(_recordable, value) { received_value = value }
    )

    field.write(Object.new, %w[alpha beta alpha])

    assert_equal %w[alpha beta], received_value
  end
end
