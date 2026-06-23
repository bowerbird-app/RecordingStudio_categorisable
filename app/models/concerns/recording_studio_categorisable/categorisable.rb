# frozen_string_literal: true

module RecordingStudioCategorisable
  module Categorisable
    extend ActiveSupport::Concern

    included do
      class_attribute :recording_studio_category_fields, instance_accessor: false, default: []
    end

    def assigned_category_items(category_group: nil)
      fields = self.class.recording_studio_category_fields
      fields = fields.select { |field| field.category_group_key == category_group.to_s } if category_group.present?

      item_recording_ids = fields.flat_map { |field| Array(field.read(self)) }.compact.uniq
      return [] if item_recording_ids.empty?

      recordings_by_id = RecordingStudio::Recording
        .where(id: item_recording_ids)
        .includes(:recordable)
        .index_by { |recording| recording.id.to_s }

      item_recording_ids.filter_map do |item_recording_id|
        recordings_by_id[item_recording_id.to_s]&.recordable
      end
    end

    class_methods do
      def categorises(attribute_name, selection:, category_group_key:, **options)
        field = build_category_field(
          attribute_name: attribute_name,
          selection: selection,
          category_group_key: category_group_key,
          options: options
        )

        register_category_field(field)

        RecordingStudioCategorisable.register_categorisable(name) do |registration|
          registration.add_field(nil, field)
        end

        define_singleton_method(attribute_name) do
          recording_studio_category_fields.find { |existing_field| existing_field.key == field.key }
        end
      end

      def available_category_groups
        category_group_keys = recording_studio_category_fields.map(&:category_group_key).uniq
        return [] if category_group_keys.empty?

        RecordingStudioCategorisable::CategoryGroup
          .where(key: category_group_keys)
          .to_a
          .sort_by { |group| [group.key.to_s, group.name.to_s.downcase] }
      end

      private

      def build_category_field(attribute_name:, selection:, category_group_key:, options:)
        RecordingStudioCategorisable::CategoryField.new(
          attribute_name: attribute_name,
          selection: selection,
          category_group_key: category_group_key,
          **options
        )
      end

      def register_category_field(field)
        self.recording_studio_category_fields = recording_studio_category_fields.reject do |existing_field|
          existing_field.key == field.key
        end + [field]
      end
    end
  end
end
