# frozen_string_literal: true

require "test_helper"

class CategoryFieldTest < Minitest::Test
  def test_single_select_normalizes_to_a_single_value
    field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :status_category_item_recording_id,
      selection: :single,
      category_group_key: "page-status"
    )

    recordable = Struct.new(:status_category_item_recording_id).new("recording-1")

    assert_equal "recording-1", field.read(recordable)
  end

  def test_multiple_select_normalizes_and_deduplicates_values
    field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :topic_category_item_recording_ids,
      selection: :multiple,
      category_group_key: "page-topics"
    )

    recordable = Struct.new(:topic_category_item_recording_ids).new(["alpha", "", "beta", "alpha"])

    assert_equal %w[alpha beta], field.read(recordable)
  end

  def test_write_uses_custom_writer_when_present
    received_value = nil
    field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :topic_category_item_recording_ids,
      selection: :multiple,
      category_group_key: "page-topics",
      value_writer: ->(_recordable, value) { received_value = value }
    )

    field.write(Object.new, %w[alpha beta alpha])

    assert_equal %w[alpha beta], received_value
  end

  def test_resolve_group_recording_selects_latest_recording_when_key_is_ambiguous
    field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :status_category_item_recording_id,
      selection: :single,
      category_group_key: "page-status"
    )

    group = Struct.new(:key)
    newest = Time.now
    oldest = newest - 3600
    relation = Struct.new(:records) do
      def includes(*)
        records
      end
    end.new(category_group_recordings(group, oldest:, newest:))
    root_recording = Struct.new(:recordings) do
      def recordings_query(**)
        recordings
      end
    end.new(relation)
    defined_group_class = RecordingStudioCategorisable.const_defined?(:CategoryGroup, false)
    RecordingStudioCategorisable.const_set(:CategoryGroup, Class.new) unless defined_group_class

    resolved = field.resolve_group_recording(root_recording: root_recording)

    assert_equal newest, resolved.created_at
  ensure
    if !defined_group_class && RecordingStudioCategorisable.const_defined?(:CategoryGroup, false)
      RecordingStudioCategorisable.send(:remove_const, :CategoryGroup)
    end
  end

  def test_available_item_recordings_reuses_cached_group_and_item_queries
    field = RecordingStudioCategorisable::CategoryField.new(
      attribute_name: :status_category_item_recording_id,
      selection: :single,
      category_group_key: "page-status"
    )

    item_recordings = [
      Struct.new(:id, :recordable).new("item-2", Struct.new(:name, :key).new("Beta", "beta")),
      Struct.new(:id, :recordable).new("item-1", Struct.new(:name, :key).new("Alpha", "alpha"))
    ]

    group_recording = build_group_recording("group-1", item_recordings)
    root_recording = build_root_recording_with_group(group_recording)
    defined_group_class = RecordingStudioCategorisable.const_defined?(:CategoryGroup, false)
    defined_item_class = RecordingStudioCategorisable.const_defined?(:CategoryItem, false)
    RecordingStudioCategorisable.const_set(:CategoryGroup, Class.new) unless defined_group_class
    RecordingStudioCategorisable.const_set(:CategoryItem, Class.new) unless defined_item_class

    2.times do
      assert_equal %w[item-1 item-2], field.available_item_recordings(root_recording: root_recording).map(&:id)
    end

    assert_equal 1, root_recording.recordings_query_calls
    assert_equal 1, group_recording.child_recordings_calls
  ensure
    if !defined_group_class && RecordingStudioCategorisable.const_defined?(:CategoryGroup, false)
      RecordingStudioCategorisable.send(:remove_const, :CategoryGroup)
    end
    if !defined_item_class && RecordingStudioCategorisable.const_defined?(:CategoryItem, false)
      RecordingStudioCategorisable.send(:remove_const, :CategoryItem)
    end
  end

  private

  def category_group_recordings(group, oldest:, newest:)
    [
      Struct.new(:recordable, :created_at).new(group.new("page-status"), oldest),
      Struct.new(:recordable, :created_at).new(group.new("page-status"), newest)
    ]
  end

  def build_root_recording_with_group(group_recording)
    Struct.new(:group_recording, :recordings_query_calls) do
      def recordings_query(**)
        self.recordings_query_calls += 1
        relation = Struct.new(:recording) do
          def includes(*)
            [recording]
          end
        end

        relation.new(group_recording)
      end
    end.new(group_recording, 0)
  end

  def build_group_recording(id, item_recordings)
    Struct.new(:id, :recordable, :child_recordings_calls) do
      def child_recordings
        self.child_recordings_calls += 1
        relation = Struct.new(:records) do
          def of_type(*)
            self
          end

          def includes(*)
            records
          end
        end

        relation.new(recordable.records)
      end
    end.new(id, Struct.new(:key, :records).new("page-status", item_recordings), 0)
  end
end
