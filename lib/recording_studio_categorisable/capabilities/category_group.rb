# frozen_string_literal: true

module RecordingStudioCategorisable
  module Capabilities
    module CategoryGroup
      def self.enabled(key:, name:, allow: {}, access: :edit, root_recordable_type: nil, **)
        RecordingStudioCategorisable.configuration.enable_category_group(
          key: key,
          name: name,
          allow: allow,
          access: access,
          root_recordable_type: root_recordable_type,
          **
        )
      end
    end
  end
end
