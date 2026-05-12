# frozen_string_literal: true

require "test_helper"

class UsageReportTest < Minitest::Test
  FakeRecording = Struct.new(:recordable)
  FakeRelation = Struct.new(:records) do
    def includes(*)
      self
    end

    def find_each(&block)
      records.each(&block)
    end
  end

  FakeRegistration = Struct.new(:relation, :field_definitions) do
    def recordable_class
      Object
    end

    def current_recordings
      relation
    end

    def fields_for(_recordable)
      field_definitions
    end
  end

  def test_item_usage_count_aggregates_registered_field_values
    status_field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :status_category_item_recording_id,
      selection: :single,
      category_group_slug: "status"
    )
    topics_field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :topic_category_item_recording_ids,
      selection: :multiple,
      category_group_slug: "topics"
    )

    page_struct = Struct.new(:status_category_item_recording_id, :topic_category_item_recording_ids)
    first_page = page_struct.new("alpha", %w[beta])
    second_page = page_struct.new("alpha", %w[beta gamma])

    registration = FakeRegistration.new(
      FakeRelation.new([FakeRecording.new(first_page), FakeRecording.new(second_page)]),
      [status_field, topics_field]
    )

    report = RecordingStudioCategorisable::UsageReport.new(registrations: [registration])

    assert_equal 2, report.item_usage_count("alpha")
    assert_equal 2, report.item_usage_count("beta")
    assert_equal 1, report.item_usage_count("gamma")
  end
end
