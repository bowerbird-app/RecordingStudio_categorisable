# frozen_string_literal: true

require "test_helper"

module RecordingStudioCategorisable
  class CategoryItemTest < ActiveSupport::TestCase
    test "uses correct table name" do
      assert_equal "recording_studio_categorisable_category_items", CategoryItem.table_name
    end

    test "validates presence of label" do
      item = CategoryItem.new
      assert_not item.valid?
      assert_includes item.errors[:label], "can't be blank"
    end

    test "validates label length" do
      item = CategoryItem.new(label: "a" * 256)
      assert_not item.valid?
      assert_includes item.errors[:label], "is too long (maximum is 255 characters)"
    end

    test "validates position is non-negative integer" do
      item = CategoryItem.new(label: "Test", position: -1)
      assert_not item.valid?
      assert_includes item.errors[:position], "must be greater than or equal to 0"
    end

    test "validates color length when present" do
      item = CategoryItem.new(label: "Test", color: "a" * 51)
      assert_not item.valid?
      assert_includes item.errors[:color], "is too long (maximum is 50 characters)"
    end

    test "can create valid category item" do
      item = CategoryItem.new(
        label: "High",
        description: "High priority",
        color: "#dc3545",
        position: 1
      )
      assert item.valid?
    end
  end
end
