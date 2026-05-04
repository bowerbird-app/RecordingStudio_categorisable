# frozen_string_literal: true

require "test_helper"

class CategoryAssignmentSourceTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  PATH = File.join(ROOT, "app/models/recording_studio_categorisable/category_assignment.rb")

  def test_source_declares_expected_table_name_and_recording_validation
    source = File.read(PATH)

    assert_includes source, "class CategoryAssignment < ApplicationRecord"
    assert_includes source, %(self.table_name = "recording_studio_categorisable_category_assignments")
    assert_includes source, "validates :category_item_recording_id, presence: true"
    assert_includes source, "def category_item_recording_must_exist"
  end
end
