# frozen_string_literal: true

require "test_helper"

class CategoryGroupSourceTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  PATH = File.join(ROOT, "app/models/recording_studio_categorisable/category_group.rb")

  def test_source_declares_expected_table_name_and_validations
    source = File.read(PATH)

    assert_includes source, "class CategoryGroup < ApplicationRecord"
    assert_includes source, %(self.table_name = "recording_studio_categorisable_category_groups")
    assert_includes source, "validates :label, presence: true"
    assert_includes source, "validates :position, numericality:"
  end
end
