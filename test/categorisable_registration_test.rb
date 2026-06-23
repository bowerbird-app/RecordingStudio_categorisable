# frozen_string_literal: true

require "test_helper"
require_relative "../app/models/concerns/recording_studio_categorisable/categorisable"

class CategorisableRegistrationTest < Minitest::Test
  def test_add_field_replaces_existing_field_with_same_attribute
    registration = RecordingStudioCategorisable::CategorisableRegistration.new("Page")

    registration.single_select(:status_category_item_recording_id, category_group_key: "status")
    registration.multi_select(:status_category_item_recording_id, category_group_key: "topics")

    assert_equal 1, registration.fields.size
    assert registration.field(:status_category_item_recording_id).multiple?
  end

  def test_fields_for_filters_to_supported_attributes
    registration = RecordingStudioCategorisable::CategorisableRegistration.new("Page")
    registration.single_select(:status_category_item_recording_id, category_group_key: "status")
    registration.multi_select(:topic_category_item_recording_ids, category_group_key: "topics")

    recordable = Struct.new(:status_category_item_recording_id).new(nil)

    assert_equal [:status_category_item_recording_id], registration.fields_for(recordable).map(&:attribute_name)
  end

  def test_categorises_defines_class_level_field_accessors
    klass = Class.new do
      include RecordingStudioCategorisable::Categorisable
    end

    Object.const_set(:CategorisableRegistrationExample, klass)
    klass.categorises(:status_category_item_recording_id, selection: :single, category_group_key: "status")
    klass.categorises(:topic_category_item_recording_ids, selection: :multiple, category_group_key: "topics")

    assert klass.status_category_item_recording_id.single?
    assert klass.topic_category_item_recording_ids.multiple?
  ensure
    Object.send(:remove_const, :CategorisableRegistrationExample) if Object.const_defined?(:CategorisableRegistrationExample)
  end

  def test_available_category_groups_returns_category_group_recordables
    klass = Class.new do
      include RecordingStudioCategorisable::Categorisable

      categorises :status_category_item_recording_id, selection: :single, category_group_key: "page-status"
      categorises :topic_category_item_recording_ids, selection: :multiple, category_group_key: "page-topics"
    end

    Object.const_set(:AvailableCategoryGroupsExample, klass)

    group_relation = Struct.new(:records) do
      def where(key:)
        records.select { |record| key.include?(record.key) }
      end

      def to_a
        records
      end
    end

    group_one = Struct.new(:key, :name).new("page-status", "Page status")
    group_two = Struct.new(:key, :name).new("page-topics", "Page topics")

    RecordingStudioCategorisable.const_set(:CategoryGroup, Class.new) unless RecordingStudioCategorisable.const_defined?(:CategoryGroup, false)
    RecordingStudioCategorisable::CategoryGroup.singleton_class.define_method(:where) do |key:|
      group_relation = Struct.new(:records) do
        def to_a
          records
        end
      end

      group_relation.new([group_one, group_two].select { |group| key.include?(group.key) })
    end

    assert_equal %w[page-status page-topics], klass.available_category_groups.map(&:key)
  ensure
    Object.send(:remove_const, :AvailableCategoryGroupsExample) if Object.const_defined?(:AvailableCategoryGroupsExample)
    RecordingStudioCategorisable.send(:remove_const, :CategoryGroup) if RecordingStudioCategorisable.const_defined?(:CategoryGroup, false)
  end

  def test_assigned_category_items_returns_selected_category_item_recordables
    klass = Class.new do
      include RecordingStudioCategorisable::Categorisable

      attr_accessor :status_category_item_recording_id, :topic_category_item_recording_ids

      categorises :status_category_item_recording_id, selection: :single, category_group_key: "page-status"
      categorises :topic_category_item_recording_ids, selection: :multiple, category_group_key: "page-topics"
    end

    Object.const_set(:AssignedCategoryItemsExample, klass)

  published = Struct.new(:key).new("published")
  product = Struct.new(:key).new("product")
  studio = Struct.new(:key).new("studio")

    recordings = [
      Struct.new(:id, :recordable).new("status-1", published),
      Struct.new(:id, :recordable).new("topic-1", product),
      Struct.new(:id, :recordable).new("topic-2", studio)
    ]
    recordings.define_singleton_method(:includes) { |_association| self }

    Object.const_set(:RecordingStudio, Module.new)
    RecordingStudio.const_set(:Recording, Class.new)
    RecordingStudio::Recording.define_singleton_method(:where) do |id:|
      selected = recordings.select { |recording| Array(id).map(&:to_s).include?(recording.id.to_s) }
      selected.define_singleton_method(:includes) { |_association| self }
      selected
    end

    page = klass.new
    page.status_category_item_recording_id = "status-1"
    page.topic_category_item_recording_ids = %w[topic-1 topic-2]

    assert_equal %w[published product studio], page.assigned_category_items.map(&:key)
    assert_equal %w[product studio], page.assigned_category_items(category_group: "page-topics").map(&:key)
  ensure
    Object.send(:remove_const, :RecordingStudio) if Object.const_defined?(:RecordingStudio)
    Object.send(:remove_const, :AssignedCategoryItemsExample) if Object.const_defined?(:AssignedCategoryItemsExample)
  end
end
