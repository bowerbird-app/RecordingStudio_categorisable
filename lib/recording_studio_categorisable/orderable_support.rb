# frozen_string_literal: true

module RecordingStudioCategorisable
  module OrderableSupport
    ORDER_GROUP_PREFIX = "category_items_"

    class << self
      def orderable_enabled?(capability)
        capability.to_h.dig(:allow, :orderable) == true
      end

      def ensure_orderable_available!(group_key: nil)
        if defined?(::RecordingStudioOrderable::OrderableRecordable) && defined?(::RecordingStudio::RecordingStudioOrder)
          return
        end

        suffix = group_key.present? ? " for category group #{group_key.inspect}" : ""
        raise MissingOrderableDependencyError,
              "Category item ordering requires the recording_studio_orderable gem#{suffix}. Install the gem and run its migrations."
      end

      def ensure_category_group_ordering!(group_key)
        ensure_orderable_available!(group_key: group_key)

        category_group_class = RecordingStudioCategorisable::CategoryGroup
        unless category_group_class < ::RecordingStudioOrderable::OrderableRecordable
          category_group_class.include(::RecordingStudioOrderable::OrderableRecordable)
        end

        order_group_key = order_group_key_for(group_key)
        return if category_group_class.recording_studio_order_group_definitions.key?(order_group_key)

        category_group_class.recording_studio_order_group(
          order_group_key,
          allows: [RecordingStudioCategorisable::CategoryItem.name]
        )
      end

      def ordered_category_items_for(group_recording, group_key)
        ensure_category_group_ordering!(group_key)
        group_recording.ordered_items_for(order_group_key_for(group_key))
      end

      def order_group_key_for(group_key)
        "#{ORDER_GROUP_PREFIX}#{group_key.to_s.tr('-', '_')}"
      end
    end
  end
end
