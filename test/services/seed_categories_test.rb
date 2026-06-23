# frozen_string_literal: true

require "test_helper"

class SeedCategoriesTest < Minitest::Test
  def setup
    # Ensure model constants are stubbed in unit test context
    RecordingStudioCategorisable.const_set(:CategoryGroup, Class.new) unless RecordingStudioCategorisable.const_defined?(:CategoryGroup, false)
    RecordingStudioCategorisable.const_set(:CategoryItem, Class.new) unless RecordingStudioCategorisable.const_defined?(:CategoryItem, false)

    @created_groups = []
    @created_items = []
  end

  def build_root(groups: [], items_by_group: {})
    created_groups = @created_groups
    created_items = @created_items

    Struct.new(:existing_groups, :existing_items_map) do
      define_method(:record) do |recordable_type, parent_recording: nil, &block|
        recordable = Struct.new(:key, :name, :description, :position).new
        block.call(recordable)

        child_items = []
        recording = Struct.new(:recordable, :child_items) do
          define_method(:child_recordings) do
            Struct.new(:records) do
              define_method(:of_type) { |_type| self }
              define_method(:includes) { |*| self }
              define_method(:find) { |&b| records.find(&b) }
              define_method(:to_a) { records }
            end.new(child_items)
          end
        end.new(recordable, child_items)

        if recordable_type == RecordingStudioCategorisable::CategoryGroup
          created_groups << recording
        elsif recordable_type == RecordingStudioCategorisable::CategoryItem
          created_items << recording
        end

        recording
      end

      define_method(:recordings_query) do |include_children: false, type: nil|
        Struct.new(:records) do
          define_method(:includes) { |*| self }
          define_method(:find) { |&b| records.find(&b) }
          define_method(:to_a) { records }
        end.new(type == RecordingStudioCategorisable::CategoryGroup ? existing_groups : [])
      end
    end.new(groups, items_by_group)
  end

  def test_creates_groups_when_keys_do_not_exist
    root = build_root(groups: [])

    RecordingStudioCategorisable::Services::SeedCategories.call(
      root_recording: root,
      category_definitions: [
        { key: "page-status", name: "Page Status", description: "Desc" }
      ]
    )

    assert_equal 1, @created_groups.size
  end

  def test_skips_groups_when_key_already_exists
    existing_recordable = Struct.new(:key).new("page-status")
    existing = Struct.new(:recordable).new(existing_recordable)
    root = build_root(groups: [existing])

    RecordingStudioCategorisable::Services::SeedCategories.call(
      root_recording: root,
      category_definitions: [
        { key: "page-status", name: "Page Status" }
      ]
    )

    assert_equal 0, @created_groups.size
  end

  def test_ignores_orphaned_group_recordings_with_nil_recordable
    orphaned = Struct.new(:recordable).new(nil)
    root = build_root(groups: [orphaned])

    RecordingStudioCategorisable::Services::SeedCategories.call(
      root_recording: root,
      category_definitions: [
        { key: "page-status", name: "Page Status" }
      ]
    )

    assert_equal 1, @created_groups.size
  end

  def test_duplicate_group_key_error_is_treated_as_already_seeded
    root = build_root(groups: [])
    root.define_singleton_method(:record) do |recordable_type, parent_recording: nil, &block|
      return super(recordable_type, parent_recording: parent_recording, &block) unless recordable_type == RecordingStudioCategorisable::CategoryGroup

      record = RecordingStudioCategorisable::CategoryGroup.new
      record.errors.add(:key, :taken)

      raise ActiveRecord::RecordInvalid.new(record)
    end

    RecordingStudioCategorisable::Services::SeedCategories.call(
      root_recording: root,
      category_definitions: [
        { key: "page-status", name: "Page Status" }
      ]
    )

    assert_equal 0, @created_groups.size
  end

  def test_creates_items_under_group_when_keys_do_not_exist
    root = build_root(groups: [])

    RecordingStudioCategorisable::Services::SeedCategories.call(
      root_recording: root,
      category_definitions: [
        {
          key: "page-status",
          name: "Page Status",
          items: [
            { key: "draft", name: "Draft", position: 1 },
            { key: "published", name: "Published", position: 2 }
          ]
        }
      ]
    )

    assert_equal 1, @created_groups.size
    assert_equal 2, @created_items.size
  end

  def test_returns_success_with_empty_list_when_no_definitions
    result = RecordingStudioCategorisable::Services::SeedCategories.call(
      root_recording: build_root,
      category_definitions: []
    )

    assert result.success?
    assert_equal [], result.value
  end

  def test_skips_group_with_empty_key_or_name
    root = build_root(groups: [])

    RecordingStudioCategorisable::Services::SeedCategories.call(
      root_recording: root,
      category_definitions: [
        { key: "", name: "Bad" },
        { key: "good", name: "" },
        { key: "real", name: "Real" }
      ]
    )

    assert_equal 1, @created_groups.size
  end
end