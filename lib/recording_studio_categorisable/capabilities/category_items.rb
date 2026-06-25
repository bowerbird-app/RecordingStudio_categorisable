# frozen_string_literal: true

module RecordingStudioCategorisable
  module Capabilities
    module CategoryItems
      def self.enabled(group_key:, allow: {}, **options)
        RecordingStudioCategorisable.configuration.enable_category_items(
          group_key: group_key,
          allow: allow,
          **options
        )
      end
    end
  end
end