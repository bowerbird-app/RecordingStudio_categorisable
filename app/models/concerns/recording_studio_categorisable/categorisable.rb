# frozen_string_literal: true

module RecordingStudioCategorisable
  module Categorisable
    extend ActiveSupport::Concern

    included do
      class_attribute :recording_studio_category_fields, instance_accessor: false, default: []
    end

    class_methods do
      def categorises(attribute_name, selection:, category_group_slug:, **options)
        field = build_category_field(
          attribute_name: attribute_name,
          selection: selection,
          category_group_slug: category_group_slug,
          options: options
        )

        register_category_field(field)

        RecordingStudioCategorisable.register_categorisable(name) do |registration|
          registration.add_field(nil, field)
        end
      end

      private

      def build_category_field(attribute_name:, selection:, category_group_slug:, options:)
        RecordingStudioCategorisable::CategoryField.new(
          attribute_name: attribute_name,
          selection: selection,
          category_group_slug: category_group_slug,
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
