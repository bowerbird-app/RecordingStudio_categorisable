# frozen_string_literal: true

module RecordingStudioCategorisable
  module Capabilities
    module CategoryGroup
      def self.enabled(key:, name:, allow: {}, **options)
        RecordingStudioCategorisable.configuration.enable_category_group(
          key: key,
          name: name,
          allow: allow,
          **options
        )
      end
    end
  end
end