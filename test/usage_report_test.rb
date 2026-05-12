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

  FakeChildRelation = Struct.new(:records) do
    def includes(*)
      self
    end

    def to_a
      records.dup
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

  def test_group_usage_count_includes_nested_descendant_items
    field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :status_category_item_recording_id,
      selection: :single,
      category_group_slug: "status"
    )

    page_struct = Struct.new(:status_category_item_recording_id)
    registration = FakeRegistration.new(
      FakeRelation.new([FakeRecording.new(page_struct.new("nested-item"))]),
      [field]
    )
    defined_group_class = RecordingStudioCategorisable.const_defined?(:CategoryGroup, false)
    defined_item_class = RecordingStudioCategorisable.const_defined?(:CategoryItem, false)
    RecordingStudioCategorisable.const_set(:CategoryGroup, Class.new) unless defined_group_class
    RecordingStudioCategorisable.const_set(:CategoryItem, Class.new) unless defined_item_class
    nested_item = Struct.new(:id, :recordable, :child_recordings).new(
      "nested-item",
      RecordingStudioCategorisable::CategoryItem.new,
      FakeChildRelation.new([])
    )
    nested_group = Struct.new(:recordable, :child_recordings).new(
      RecordingStudioCategorisable::CategoryGroup.new,
      FakeChildRelation.new([nested_item])
    )
    root_group = Struct.new(:child_recordings).new(FakeChildRelation.new([nested_group]))

    report = RecordingStudioCategorisable::UsageReport.new(registrations: [registration])

    assert_equal 1, report.group_usage_count(root_group)
    assert report.group_in_use?(root_group)
  ensure
    RecordingStudioCategorisable.send(:remove_const, :CategoryGroup) unless defined_group_class
    RecordingStudioCategorisable.send(:remove_const, :CategoryItem) unless defined_item_class
  end
end
