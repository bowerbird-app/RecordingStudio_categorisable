# frozen_string_literal: true

require "test_helper"

module RecordingStudioCategorisable
  class CategoryGroupTest < ActiveSupport::TestCase
    test "uses correct table name" do
      assert_equal "recording_studio_categorisable_category_groups", CategoryGroup.table_name
    end

    test "validates presence of label" do
      group = CategoryGroup.new
      assert_not group.valid?
      assert_includes group.errors[:label], "can't be blank"
    end

    test "validates label length" do
      group = CategoryGroup.new(label: "a" * 256)
      assert_not group.valid?
      assert_includes group.errors[:label], "is too long (maximum is 255 characters)"
    end

    test "validates position is non-negative integer" do
      group = CategoryGroup.new(label: "Test", position: -1)
      assert_not group.valid?
      assert_includes group.errors[:position], "must be greater than or equal to 0"
    end

    test "can create valid category group" do
      group = CategoryGroup.new(
        label: "Priority",
        description: "Priority levels",
        position: 1
      )
      assert group.valid?
    end
  end
end
