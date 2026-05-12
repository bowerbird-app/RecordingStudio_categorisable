# frozen_string_literal: true

module RecordingStudioCategorisable
  class Error < StandardError; end

  class InvalidCategorySelectionError < Error; end

  class AmbiguousCategoryGroupError < Error; end

  class MissingRootRecordingError < Error; end

  class MissingAuthorizationError < Error; end

  class UnauthorizedError < Error; end
end
