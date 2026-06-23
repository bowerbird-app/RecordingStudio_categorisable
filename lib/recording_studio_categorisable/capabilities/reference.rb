# frozen_string_literal: true

module RecordingStudioCategorisable
  module Capabilities
    module Reference
      def self.enabled(recordable:, attribute_name:, category_group_key:, selection:, **options)
        ensure_categorisable!(recordable)

        recordable.enable_category_reference(
          attribute_name: attribute_name,
          category_group_key: category_group_key,
          selection: selection,
          **options
        )

        RecordingStudioCategorisable.configuration.enable_reference(
          recordable: recordable,
          attribute_name: attribute_name,
          category_group_key: category_group_key,
          selection: selection,
          **options
        )
      end

      def self.ensure_categorisable!(recordable)
        return if recordable < RecordingStudioCategorisable::Categorisable

        recordable.include(RecordingStudioCategorisable::Categorisable)
      end
    end
  end
end