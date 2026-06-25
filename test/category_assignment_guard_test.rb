# frozen_string_literal: true

require "test_helper"

class CategoryAssignmentGuardTest < Minitest::Test
  Field = Struct.new(:attribute_name, :category_group_key)

  def test_ensure_required_references_raises_when_required_mapping_is_missing
    fields = [Field.new(:topic_category_item_recording_ids, "page-topics")]

    error = assert_raises(RecordingStudioCategorisable::InvalidCategorySelectionError) do
      RecordingStudioCategorisable::CategoryAssignmentGuard.ensure_required_references!(
        fields: fields,
        required_references: {
          status_category_item_recording_id: "page-status"
        }
      )
    end

    assert_includes error.message, "missing required category reference configuration"
    assert_includes error.message, "status_category_item_recording_id=>page-status"
  end

  def test_ensure_required_references_allows_matching_mapping
    fields = [Field.new(:status_category_item_recording_id, "page-status")]

    RecordingStudioCategorisable::CategoryAssignmentGuard.ensure_required_references!(
      fields: fields,
      required_references: {
        status_category_item_recording_id: "page-status"
      }
    )
  end

  def test_reject_unexpected_attributes_raises_for_unknown_category_attribute
    fields = [Field.new(:status_category_item_recording_id, "page-status")]

    error = assert_raises(RecordingStudioCategorisable::InvalidCategorySelectionError) do
      RecordingStudioCategorisable::CategoryAssignmentGuard.reject_unexpected_attributes!(
        submitted_params: {
          title: "Hello",
          rogue_category_item_recording_id: "123"
        },
        fields: fields
      )
    end

    assert_includes error.message, "contains unexpected category attributes"
    assert_includes error.message, "rogue_category_item_recording_id"
  end

  def test_reject_unexpected_attributes_allows_registered_category_attributes
    fields = [
      Field.new(:status_category_item_recording_id, "page-status"),
      Field.new(:topic_category_item_recording_ids, "page-topics")
    ]

    RecordingStudioCategorisable::CategoryAssignmentGuard.reject_unexpected_attributes!(
      submitted_params: {
        status_category_item_recording_id: "123",
        topic_category_item_recording_ids: %w[1 2]
      },
      fields: fields
    )
  end
end
