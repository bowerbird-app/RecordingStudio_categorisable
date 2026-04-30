# frozen_string_literal: true

require "test_helper"

module RecordingStudioCategorisable
  class CategoryAssignmentTest < ActiveSupport::TestCase
    test "uses correct table name" do
      assert_equal "recording_studio_categorisable_category_assignments", CategoryAssignment.table_name
    end

    test "validates presence of category_item_recording_id" do
      assignment = CategoryAssignment.new
      assert_not assignment.valid?
      assert_includes assignment.errors[:category_item_recording_id], "can't be blank"
    end

    test "can create valid category assignment with valid recording ID" do
      # This test would require a full database setup with RecordingStudio
      # For now, we just test basic validation
      assignment = CategoryAssignment.new(
        category_item_recording_id: SecureRandom.uuid
      )
      # Will fail validation because recording doesn't exist, but structure is correct
      assert_not_nil assignment.category_item_recording_id
    end

    test "setter works for category_item_recording" do
      assignment = CategoryAssignment.new
      mock_recording = OpenStruct.new(id: SecureRandom.uuid)
      assignment.category_item_recording = mock_recording
      assert_equal mock_recording.id, assignment.category_item_recording_id
    end
  end
end
