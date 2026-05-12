# frozen_string_literal: true

require "test_helper"

class CategorisableRegistrationTest < Minitest::Test
  def test_add_field_replaces_existing_field_with_same_attribute
    registration = RecordingStudioCategorisable::CategorisableRegistration.new("Page")

    registration.single_select(:status_category_item_recording_id, category_group_slug: "status")
    registration.multi_select(:status_category_item_recording_id, category_group_slug: "topics")

    assert_equal 1, registration.fields.size
    assert registration.field(:status_category_item_recording_id).multiple?
  end

  def test_fields_for_filters_to_supported_attributes
    registration = RecordingStudioCategorisable::CategorisableRegistration.new("Page")
    registration.single_select(:status_category_item_recording_id, category_group_slug: "status")
    registration.multi_select(:topic_category_item_recording_ids, category_group_slug: "topics")

    recordable = Struct.new(:status_category_item_recording_id).new(nil)

    assert_equal [:status_category_item_recording_id], registration.fields_for(recordable).map(&:attribute_name)
  end
end
