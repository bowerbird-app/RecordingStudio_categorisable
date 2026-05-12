# frozen_string_literal: true

module RecordingStudioCategorisable
  class Error < StandardError; end

  class InvalidCategorySelectionError < Error; end

  class MissingRootRecordingError < Error; end
end
